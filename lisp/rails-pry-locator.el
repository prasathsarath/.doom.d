;;; rails-pry-locator.el -*- lexical-binding: t; -*-

(require 'json)
(require 'project)
(require 'subr-x)
(require 'xref)

(defconst rails-pry-locator--ruby
  (mapconcat
   #'identity
   '("require 'json'"
     "begin"
     "  require 'pry'"
     "rescue LoadError"
     "  puts '__RAILS_PRY_LOCATOR_ERROR__pry-missing'"
     "  exit"
     "end"
     "query = ENV.fetch('RAILS_PRY_LOOKUP').downcase"
     "root = Rails.root.to_s"
     "results = []"
     "Rails.application.eager_load!"
     "ObjectSpace.each_object(Module) do |mod|"
     "  next if mod.name.nil? || mod.name.empty?"
     "  [Pry::Method.all_from_class(mod, false), Pry::Method.all_from_obj(mod, false)].flatten.each do |method|"
     "    next unless method.name.to_s.downcase.include?(query)"
     "    file, line = method.source_location"
     "    file = File.expand_path(file) if file"
     "    next unless file && file.start_with?(root + File::SEPARATOR) && File.file?(file)"
     "    results << { kind: 'method', name: method.name_with_owner, file: file, line: line }"
     "  end"
     "rescue StandardError"
     "  next"
     "end"
     "field_names = ObjectSpace.each_object(Class).filter_map do |klass|"
     "  next unless klass.respond_to?(:fields)"
     "  klass.fields.each_key.select { |name| name.downcase.include?(query) }"
     "rescue StandardError"
     "  nil"
     "end.flatten.uniq"
     "unless field_names.empty?"
     "  Dir.glob(Rails.root.join('{app,lib}/**/*.rb')).sort.each do |file|"
     "    File.foreach(file).with_index(1) do |source_line, line_number|"
     "      field_names.each do |field_name|"
     "        escaped = Regexp.escape(field_name)"
     "        next unless source_line.match?(/^\\s*field\\s*(?:\\(\\s*)?(?::#{escaped}\\b|[\"']#{escaped}[\"'])/)"
     "        results << { kind: 'field', name: \"field :#{field_name}\", file: File.expand_path(file), line: line_number }"
     "      end"
     "    end"
     "  end"
     "end"
     "results.uniq! { |result| [result[:kind], result[:name], result[:file], result[:line]] }"
     "results.sort_by! { |result| [result[:kind], result[:name], result[:file], result[:line]] }"
     "puts '__RAILS_PRY_LOCATOR__' + JSON.generate(results)")
   "\n"))

(defun rails-pry-locator--project-root ()
  (or (when (fboundp 'projectile-project-root)
        (ignore-errors (projectile-project-root)))
      (when-let ((project (project-current nil)))
        (project-root project))
      (user-error "Not inside a project")))

(defun rails-pry-locator--jump (result origin)
  (let ((file (alist-get 'file result))
        (line (alist-get 'line result)))
    (xref-push-marker-stack (copy-marker origin))
    (pop-to-buffer-same-window (find-file-noselect file))
    (widen)
    (goto-char (point-min))
    (forward-line (1- line))
    (back-to-indentation)))

(defun rails-pry-locator--select (results root origin)
  (if (null results)
      (message "No runtime method or Mongoid field matched")
    (let* ((choices
            (mapcar
             (lambda (result)
               (cons
                (format "[%s] %s — %s:%s"
                        (alist-get 'kind result)
                        (alist-get 'name result)
                        (file-relative-name (alist-get 'file result) root)
                        (alist-get 'line result))
                result))
             results))
           (choice
            (condition-case nil
                (completing-read
                 "Runtime definition (RET: open, ESC: cancel): " choices nil t)
              (quit nil))))
      (when choice
        (rails-pry-locator--jump (cdr (assoc choice choices)) origin)))))

(defun rails-pry-locator--finished (process _event)
  (when (memq (process-status process) '(exit signal))
    (let ((buffer (process-buffer process))
          (root (process-get process 'root))
          (origin (process-get process 'origin)))
      (if (/= (process-exit-status process) 0)
          (progn
            (display-buffer buffer)
            (message "Pry locator failed; see %s" (buffer-name buffer)))
        (unwind-protect
            (with-current-buffer buffer
              (goto-char (point-min))
              (cond
               ((re-search-forward
                 "^__RAILS_PRY_LOCATOR_ERROR__pry-missing$" nil t)
                (message "Pry is not available in this Rails bundle"))
               ((re-search-forward "^__RAILS_PRY_LOCATOR__\\(.*\\)$" nil t)
                (rails-pry-locator--select
                 (json-parse-string
                  (match-string-no-properties 1)
                  :array-type 'list
                  :object-type 'alist)
                 root
                 origin))
               (t
                (display-buffer buffer)
                (message "Pry locator returned no parseable result"))))
          (when (buffer-live-p buffer)
            (kill-buffer buffer))))
      (set-marker origin nil))))

(defun rails-pry-find-definition (keyword)
  "Find runtime methods and Mongoid fields matching KEYWORD.
With a prefix argument, prompt for KEYWORD instead of using the symbol at point."
  (interactive
   (list
    (let ((symbol (thing-at-point 'symbol t)))
      (if (and symbol (not current-prefix-arg))
          symbol
        (read-string
         "Runtime method/field keyword (RET: search, ESC: cancel): " symbol)))))
  (when (string-empty-p keyword)
    (user-error "Keyword must not be empty"))
  (let* ((root (file-name-as-directory
                (expand-file-name (rails-pry-locator--project-root))))
         (runner (expand-file-name "bin/rails" root))
         (origin (point-marker))
         (buffer (generate-new-buffer " *rails-pry-locator*"))
         (default-directory root)
         (process-environment
          (cons (concat "RAILS_PRY_LOOKUP=" keyword) process-environment)))
    (unless (file-executable-p runner)
      (user-error "%s is not executable" runner))
    (message "Loading Rails and searching runtime definitions for %s…" keyword)
    (let ((process
           (make-process
            :name "rails-pry-locator"
            :buffer buffer
            :command (list runner "runner" rails-pry-locator--ruby)
            :noquery t)))
      (process-put process 'root root)
      (process-put process 'origin origin)
      (set-process-sentinel process #'rails-pry-locator--finished))))

(map! :after ruby-mode
      :map ruby-mode-map
      :localleader
      :desc "Pry runtime definition"
      "g p" #'rails-pry-find-definition)

(provide 'rails-pry-locator)
