;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
(setq doom-font (font-spec :family "Go Mono for Powerline" :size 15 :weight 'normal)
    doom-variable-pitch-font (font-spec :family "Fira Sans" :size 14))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
;; (setq doom-theme 'doom-solarized-light)
(use-package! circadian
  :config
  (setq calendar-latitude 12.935082)   ; Set your latitude
  (setq calendar-longitude 77.5772033) ; Set your longitude
  (setq circadian-themes '((:sunrise . doom-solarized-light)
                           (:sunset  . doom-solarized-dark)))
  (circadian-setup))

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

;; Custom Config Starts

(add-to-list 'initial-frame-alist '(fullscreen . maximized)) ;; for maximizing to mac screen space

;; START TABS CONFIG
;; Create a variable for our preferred tab width
(setq custom-tab-width 2)

;; Two callable functions for enabling/disabling tabs in Emacs
(defun disable-tabs () (setq indent-tabs-mode nil))
(defun enable-tabs  ()
  (local-set-key (kbd "TAB") 'tab-to-tab-stop)
  (setq indent-tabs-mode t)
  (setq tab-width custom-tab-width))

;; Hooks to Enable Tabs
(add-hook 'prog-mode-hook 'disable-tabs)
;; Hooks to Disable Tabs
;;(add-hook 'lisp-mode-hook 'disable-tabs)
;;(add-hook 'emacs-lisp-mode-hook 'disable-tabs)

;; Language-Specific Tweaks
;;(setq-default python-indent-offset custom-tab-width) ;; Python
;;(setq-default js-indent-level custom-tab-width)      ;; Javascript


;; Making electric-indent behave sanely
(setq-default electric-indent-inhibit t)

;; Make the backspace properly erase the tab instead of
;; removing 1 space at a time.
(setq backward-delete-char-untabify-method 'hungry)

;; (OPTIONAL) Shift width for evil-mode users
;; For the vim-like motions of ">>" and "<<".
(setq-default evil-shift-width custom-tab-width)

;; WARNING: This will change your life
;; (OPTIONAL) Visualize tabs as a pipe character - "|"
;; This will also show trailing characters as they are useful to spot.
(setq whitespace-style '(face tabs tab-mark trailing))
(custom-set-faces
 '(whitespace-tab ((t (:foreground "#636363")))))
(setq whitespace-display-mappings
  '((tab-mark 9 [124 9] [92 9]))) ; 124 is the ascii ID for '\|'
(global-whitespace-mode) ; Enable whitespace mode everywhere
; END TABS CONFIG

(setq mode-require-final-newline nil);; avoid adding a new line at the end of file
;;
(defun my-put-file-name-on-clipboard ()
  "Put the current file name on the clipboard"
  (interactive)
  (let ((filename (if (equal major-mode 'dired-mode)
                      default-directory
                    (buffer-file-name))))
    (when filename
      (with-temp-buffer
        (insert filename)
        (clipboard-kill-region (point-min) (point-max)))
      (message filename))))

(after! rspec-mode
  (setq rspec-spec-command "bundle exec rspec -cfd --options --fail-fast"))

(setq auth-sources '("~/.authinfo"))

;; Optionally, bind the function to a key for easy access
(map! :leader
      :desc "Run StandardRB fix"
      "m c f" #'run-standardrb-fix)

(setq
 gptel-model 'deepseek-r1:1.5b
 gptel-backend (gptel-make-ollama "Ollama"
                 :host "localhost:11434"
                 :stream t
                 :models '(deepseek-r1:1.5b)))


(add-to-list 'auto-mode-alist '("\\.cap\\'" . ruby-mode))


(add-hook 'after-init-hook 'inf-ruby-switch-setup)
(setq compilation-scroll-output t)

(setq auth-sources '("~/.authinfo.gpg"))

(after! lsp-mode
  ;; Ignore directories
  (add-to-list 'lsp-file-watch-ignored-directories "[/\\\\]node_modules\\'")
  (add-to-list 'lsp-file-watch-ignored-directories "[/\\\\]tmp\\'")
  ;; Ignore .log files
  (add-to-list 'lsp-file-watch-ignored-files "[/\\\\][^/\\\\]+\\.log\\'"))

(setq plantuml-executable-path "/opt/homebrew/bin/plantuml")
(setq plantuml-default-exec-mode 'executable)


(defun gptel-api-key-from-environment (&optional var)
  (lambda ()
    (getenv (or var                     ;provided key
                (thread-first           ;or fall back to <TYPE>_API_KEY
                  (type-of gptel-backend)
                  (symbol-name)
                  (substring 6)
                  (upcase)
                  (concat "_API_KEY"))))))


;; OpenRouter offers an OpenAI compatible API
(setq gptel-model   'gpt-oss:latest
      gptel-backend
      (gptel-make-openai "OpenRouter"               ;Any name you want
        :endpoint "/v1/chat/completions"
        :stream t
        :key (gptel-api-key-from-environment "ONEAPI_KEY")                   ;can be a function that returns the key
        :models '(bge-m3:latest
                  bge-reranker-v2-m3
                  deepseek-r1:32b
                  deepseek/deepseek-v3.2
                  deepseek/deepseek-v3.2-exp
                  deepseek/deepseek-v3.2-speciale
                  devstral-small-2:latest
                  embeddinggemma:latest
                  gemma3:12b
                  gemma3:27b
                  gemma3n:latest
                  glm-5
                  gpt-oss:latest
                  hf.co/Qwen/Qwen3-Embedding-8B-GGUF:Q8_0
                  hf.co/TeichAI/Nemotron-Orchestrator-8B-DeepSeek-v3.2-Speciale-Distill-GGUF:Q8_0
                  kimi-k2.5
                  linux6200/bge-reranker-v2-m3:latest
                  minimax-m2.5
                  minimax/minimax-m2.5
                  moonshotai/kimi-k2.5
                  nemotron-3-nano:latest
                  nomic-embed-text-v2-moe:latest
                  nomic-embed-text:latest
                  olmo-3.1:latest
                  openai/gpt-oss-120b
                  qwen/qwen3.5-397b-a17b
                  qwen3-coder:30b
                  qwen3-embedding:latest
                  qwen3:32b
                  rnj-1:8b
                  translategemma:27b
                  z-ai/glm-4.7
                  z-ai/glm-4.7-flash
                  z-ai/glm-5)))


