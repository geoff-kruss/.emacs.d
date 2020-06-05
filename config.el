(require 'use-package-ensure)
(setq use-package-always-ensure t)

(use-package auto-compile :config (auto-compile-on-load-mode))
(setq load-prefer-newer t)

(setq gnutls-algorithm-priority "NORMAL:-VERS-TLS1.3")

(load-file "~/.emacs.d/sensible-defaults.el")
(sensible-defaults/use-all-settings)
(sensible-defaults/use-all-keybindings)
(sensible-defaults/backup-to-temp-directory)

(setq user-full-name "Geoff Kruss"
      user-email-address "geoffkruss@gmail.com"
      calendar-latitude -33.92
      calendar-longitude 18.42
      calendar-location-name "Cape Town")

(add-to-list 'load-path "~/.emacs.d/resources/")

(defun hrs/rename-file (new-name)
  (interactive "FNew name: ")
  (let ((filename (buffer-file-name)))
    (if filename
        (progn
          (when (buffer-modified-p)
            (save-buffer))
          (rename-file filename new-name t)
          (kill-buffer (current-buffer))
          (find-file new-name)
          (message "Renamed '%s' -> '%s'" filename new-name))
      (message "Buffer '%s' isn't backed by a file!" (buffer-name)))))

(defun hrs/generate-scratch-buffer ()
  "Create and switch to a temporary scratch buffer with a random
       name."
  (interactive)
  (switch-to-buffer (make-temp-name "scratch-")))

(defun hrs/kill-current-buffer ()
  "Kill the current buffer without prompting."
  (interactive)
  (kill-buffer (current-buffer)))

(defun hrs/visit-last-migration ()
  "Open the most recent Rails migration. Relies on projectile."
  (interactive)
  (let ((migrations
         (directory-files
          (expand-file-name "db/migrate" (projectile-project-root)) t)))
    (find-file (car (last migrations)))))

(defun hrs/add-auto-mode (mode &rest patterns)
  "Add entries to `auto-mode-alist' to use `MODE' for all given file `PATTERNS'."
  (dolist (pattern patterns)
    (add-to-list 'auto-mode-alist (cons pattern mode))))

(defun hrs/find-file-as-sudo ()
  (interactive)
  (let ((file-name (buffer-file-name)))
    (when file-name
      (find-alternate-file (concat "/sudo::" file-name)))))

(defun hrs/region-or-word ()
  (if mark-active
      (buffer-substring-no-properties (region-beginning)
                                      (region-end))
    (thing-at-point 'word)))

(defun hrs/append-to-path (path)
  "Add a path both to the $PATH variable and to Emacs' exec-path."
  (setenv "PATH" (concat (getenv "PATH") ":" path))
  (add-to-list 'exec-path path))

(defun hrs/insert-password ()
  (interactive)
  (shell-command "pwgen 30 -1" t))

(defun hrs/notify-send (title message)
  "Display a desktop notification by shelling out to `notify-send'."
  (call-process-shell-command
   (format "notify-send -t 2000 \"%s\" \"%s\"" title message)))

(tool-bar-mode 0)
(menu-bar-mode 0)
(scroll-bar-mode -1)

(set-window-scroll-bars (minibuffer-window) nil nil)

(setq frame-title-format '((:eval (projectile-project-name))))

(global-prettify-symbols-mode -1)

(use-package doom-themes
  :config
  ;; Global settings (defaults)
  (setq doom-themes-enable-bold t    ; if nil, bold is universally disabled
        doom-themes-enable-italic t) ; if nil, italics is universally disabled
  (load-theme 'doom-one t)
  ;; Enable flashing mode-line on errors
  (doom-themes-visual-bell-config)

  ;; Corrects (and improves) org-mode's native fontification.
  (doom-themes-org-config)
  (defun transparency (value)
    "Sets the transparency of the frame window. 0=transparent/100=opaque."
    (interactive "nTransparency Value 0 - 100 opaque:")
    (set-frame-parameter (selected-frame) 'alpha value))
  (defun hrs/apply-theme ()
    "Apply the `hickey' theme and make frames just slightly transparent."
    (interactive)
    (load-theme 'doom-one t)
    (transparency 90)))

(if (daemonp)
    (add-hook 'after-make-frame-functions
              (lambda (frame)
                (with-selected-frame frame (hrs/apply-theme))))
  (hrs/apply-theme))

(use-package moody
  :config
  (setq x-underline-at-descent-line t
        moody-mode-line-height 30)
  (moody-replace-mode-line-buffer-identification)
  (moody-replace-vc-mode))

(use-package minions
  :config
  (setq minions-mode-line-lighter ""
        minions-mode-line-delimiters '("" . ""))
  (minions-mode 1))

(setq ring-bell-function 'ignore)

(setq scroll-conservatively 100)

(setq hrs/default-font "Jetbrains Mono")
(setq hrs/default-font-size 14)
(setq hrs/current-font-size hrs/default-font-size)

(setq hrs/font-change-increment 1.1)

(defun hrs/font-code ()
  "Return a string representing the current font (like \"Inconsolata-14\")."
  (concat hrs/default-font "-" (number-to-string hrs/current-font-size)))

(defun hrs/set-font-size ()
  "Set the font to `hrs/default-font' at `hrs/current-font-size'.
Set that for the current frame, and also make it the default for
other, future frames."
  (let ((font-code (hrs/font-code)))
    (if (assoc 'font default-frame-alist)
        (setcdr (assoc 'font default-frame-alist) font-code)
      (add-to-list 'default-frame-alist (cons 'font font-code)))
    (set-frame-font font-code)))

(defun hrs/reset-font-size ()
  "Change font size back to `hrs/default-font-size'."
  (interactive)
  (setq hrs/current-font-size hrs/default-font-size)
  (hrs/set-font-size))

(defun hrs/increase-font-size ()
  "Increase current font size by a factor of `hrs/font-change-increment'."
  (interactive)
  (setq hrs/current-font-size
        (ceiling (* hrs/current-font-size hrs/font-change-increment)))
  (hrs/set-font-size))

(defun hrs/decrease-font-size ()
  "Decrease current font size by a factor of `hrs/font-change-increment', down to a minimum size of 1."
  (interactive)
  (setq hrs/current-font-size
        (max 1
             (floor (/ hrs/current-font-size hrs/font-change-increment))))
  (hrs/set-font-size))

(define-key global-map (kbd "C-)") 'hrs/reset-font-size)
(define-key global-map (kbd "C-+") 'hrs/increase-font-size)
(define-key global-map (kbd "C-=") 'hrs/increase-font-size)
(define-key global-map (kbd "C-_") 'hrs/decrease-font-size)
(define-key global-map (kbd "C--") 'hrs/decrease-font-size)

(hrs/reset-font-size)

(global-hl-line-mode)

(use-package diff-hl
  :config
  (add-hook 'prog-mode-hook 'turn-on-diff-hl-mode)
  (add-hook 'vc-dir-mode-hook 'turn-on-diff-hl-mode))

(use-package ag)

(use-package avy
  :bind*
  ("C-;" . avy-goto-char-timer))

(use-package company)
(add-hook 'after-init-hook 'global-company-mode)
(global-set-key (kbd "TAB") #'company-indent-or-complete-common)
(setq company-idle-delay nil)

(global-set-key (kbd "M-/") 'company-complete-common)

(use-package let-alist)
(use-package flycheck)

(use-package projectile
  :bind
  ("C-c v" . projectile-ag)

  :config
  (define-key projectile-mode-map (kbd "C-c p") 'projectile-command-map)
  (setq projectile-completion-system 'ivy)
  (setq projectile-switch-project-action 'projectile-dired)
  (setq projectile-require-project-root nil))

(use-package counsel
  :bind
  ("M-x" . 'counsel-M-x)
  ("C-s" . 'swiper)

  :config
  (use-package flx)
  (use-package smex)

  (ivy-mode 1)
  (setq ivy-use-virtual-buffers t)
  (setq ivy-count-format "(%d/%d) ")
  (setq ivy-initial-inputs-alist nil)
  (setq ivy-re-builders-alist
        '((swiper . ivy--regex-plus)
          (t . ivy--regex-fuzzy))))

(defun hrs/split-window-below-and-switch ()
  "Split the window horizontally, then switch to the new pane."
  (interactive)
  (split-window-below)
  (balance-windows)
  (other-window 1))

(defun hrs/split-window-right-and-switch ()
  "Split the window vertically, then switch to the new pane."
  (interactive)
  (split-window-right)
  (balance-windows)
  (other-window 1))

(global-set-key (kbd "C-x 2") 'hrs/split-window-below-and-switch)
(global-set-key (kbd "C-x 3") 'hrs/split-window-right-and-switch)

(projectile-global-mode)

(use-package undo-tree)

(setq-default tab-width 2)

(use-package subword
  :config (global-subword-mode 1))

(use-package css-mode
  :config
  (setq css-indent-offset 2))

(use-package scss-mode
  :config
  (setq scss-compile-at-save nil))

(use-package less-css-mode)

(use-package coffee-mode)

(setq js-indent-level 2)

(add-hook 'coffee-mode-hook
          (lambda ()
            (yas-minor-mode 1)
            (setq coffee-tab-width 2)))

(use-package paredit)

(use-package rainbow-delimiters)

(setq lispy-mode-hooks
      '(clojure-mode-hook
        emacs-lisp-mode-hook
        lisp-mode-hook
        scheme-mode-hook))

(dolist (hook lispy-mode-hooks)
  (add-hook hook (lambda ()
                   (setq show-paren-style 'expression)
                   (paredit-mode)
                   (rainbow-delimiters-mode))))

(use-package eldoc
  :config
  (add-hook 'emacs-lisp-mode-hook 'eldoc-mode))

(use-package flycheck-package)

(eval-after-load 'flycheck
  '(flycheck-package-setup))

(use-package python-mode)

(hrs/append-to-path "~/.local/bin")

(use-package elpy)
(elpy-enable)

(add-hook 'elpy-mode-hook 'flycheck-mode)

(use-package terraform-mode)
(use-package company-terraform)

(use-package yaml-mode)

(use-package markdown-mode
  :commands gfm-mode

  :mode (("\\.md$" . gfm-mode))

  :config
  (setq markdown-command "pandoc --standalone --mathjax --from=markdown")
  (custom-set-faces
   '(markdown-code-face ((t nil)))))

(use-package dired-open
  :config
  (setq dired-open-extensions
        '(("avi" . "mpv")
          ("cbr" . "comix")
          ("doc" . "abiword")
          ("docx" . "abiword")
          ("gif" . "ffplay")
          ("gnumeric" . "gnumeric")
          ("html" . "firefox")
          ("jpeg" . "s")
          ("jpg" . "s")
          ("mkv" . "mpv")
          ("mov" . "mpv")
          ("mp3" . "mpv")
          ("mp4" . "mpv")
          ("pdf" . "zathura")
          ("png" . "s")
          ("webm" . "mpv")
          ("xls" . "gnumeric")
          ("xlsx" . "gnumeric"))))

(setq-default dired-listing-switches "-lhvA")
(add-hook 'dired-mode-hook (lambda () (dired-hide-details-mode 1)))

(setq dired-dwim-target t)

(setq dired-clean-up-buffers-too t)

(setq dired-recursive-copies 'always)

(setq dired-recursive-deletes 'top)

(global-set-key (kbd "C-x k") 'hrs/kill-current-buffer)

(use-package helpful)
(global-set-key (kbd "C-h f") #'helpful-callable)
(global-set-key (kbd "C-h v") #'helpful-variable)
(global-set-key (kbd "C-h k") #'helpful-key)

(hrs/append-to-path "/usr/local/bin")

(save-place-mode t)

(setq-default indent-tabs-mode nil)

(use-package which-key
  :config (which-key-mode))

(add-to-list 'load-path "~/.emacs.d/hideshow-org")
(require 'hideshow-org)

(use-package idle-highlight-mode
  :config
  (add-hook 'prog-mode-hook
            (lambda ()
              (idle-highlight-mode t))))

(use-package smartparens
  :defer t
  :ensure t
  :diminish smartparens-mode
  :init
  (setq sp-override-key-bindings
        '(("C-<right>" . nil)
          ("C-<left>" . nil)
          ("C-)" . sp-forward-slurp-sexp)
          ("M-<backspace>" . nil)
          ("C-(" . sp-forward-barf-sexp)))
  :config
  (sp-use-smartparens-bindings)
  (sp--update-override-key-bindings)
  :commands (smartparens-mode show-smartparens-mode))

(use-package cider-eval-sexp-fu
  :defer t)

(use-package clj-refactor
  :defer t
  :ensure t
  :diminish clj-refactor-mode
  :config (cljr-add-keybindings-with-prefix "C-c C-m"))

(use-package cider
  :ensure t
  :defer t
  :init (add-hook 'cider-mode-hook #'clj-refactor-mode)
  :diminish subword-mode
  :config
  (setq nrepl-log-messages t
        cider-repl-display-in-current-window t
        cider-repl-use-clojure-font-lock t
        cider-prompt-save-file-on-load 'always-save
        cider-font-lock-dynamically '(macro core function var)
        nrepl-hide-special-buffers t
        cider-overlays-use-font-lock t)
  (add-hook 'cider-repl-mode-hook #'cider-company-enable-fuzzy-completion)
  (add-hook 'cider-mode-hook #'cider-company-enable-fuzzy-completion)
  (cider-repl-toggle-pretty-printing))

;; First install the package:
(use-package flycheck-clj-kondo
  :ensure t)

(use-package flycheck-joker
  :ensure t)

(use-package clojure-mode
  :ensure t
  :mode (("\\.clj\\'" . clojure-mode)
         ("\\.edn\\'" . clojure-mode))
  :config
  (setq clojure-align-forms-automatically t)
  (show-paren-mode 1)
  (setq-default blink-matching-paren nil
                show-paren-style 'parenthesis
                show-paren-delay 0)
  (require 'flycheck-joker)
  (require 'flycheck-clj-kondo)
  (dolist (checker '(clj-kondo-clj clj-kondo-cljs clj-kondo-cljc clj-kondo-edn))
  (setq flycheck-checkers (cons checker (delq checker flycheck-checkers))))
  (dolist (checkers '((clj-kondo-clj . clojure-joker)
                      (clj-kondo-cljs . clojurescript-joker)
                      (clj-kondo-cljc . clojure-joker)
                      (clj-kondo-edn . edn-joker)))
                      (flycheck-add-next-checker (car checkers) (cons 'error (cdr checkers))))
  :init
  (add-hook 'clojure-mode-hook #'linum-mode)
  (add-hook 'clojure-mode-hook #'subword-mode)
  (add-hook 'clojure-mode-hook #'paredit-mode)
  (add-hook 'clojure-mode-hook #'cider-mode)
  (add-hook 'clojure-mode-hook #'rainbow-delimiters-mode)
  (add-hook 'clojure-mode-hook #'eldoc-mode)
  (add-hook 'clojure-mode-hook #'flycheck-mode)
  (add-hook 'clojure-mode-hook #'idle-highlight-mode)
  (add-hook 'clojure-mode-hook #'hs-org/minor-mode))
