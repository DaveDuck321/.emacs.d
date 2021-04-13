;;----------------------------------------------------------------------------
;; Emacs has some insane default bindings, lets fix those.
;;----------------------------------------------------------------------------

;; Just assume I want to kill the current buffer
(global-set-key (kbd "C-x k") 'kill-this-buffer)

;; I keep hitting ESC by accident (Vim's fault 🤮). Since I've got an ALT key, I'll override the default
(define-key key-translation-map (kbd "ESC") (kbd "C-g"))

;; I've gotta remember not to use the arrow keys
(global-unset-key (kbd "<left>"))
(global-unset-key (kbd "<right>"))
(global-unset-key (kbd "<up>"))
(global-unset-key (kbd "<down>"))
(global-unset-key (kbd "<C-left>"))
(global-unset-key (kbd "<C-right>"))
(global-unset-key (kbd "<C-up>"))
(global-unset-key (kbd "<C-down>"))
(global-unset-key (kbd "<M-left>"))
(global-unset-key (kbd "<M-right>"))
(global-unset-key (kbd "<M-up>"))
(global-unset-key (kbd "<M-down>"))


;; Emulate vim's 'o' key (which is its best feature tbh)
(global-set-key (kbd "M-o") (lambda () (interactive)(beginning-of-line)(open-line 1)))
(global-set-key (kbd "C-o") (lambda () (interactive)(end-of-line)(newline-and-indent)))
(global-set-key (kbd "<C-return>") (lambda () (interactive)(end-of-line)(newline-and-indent)))


;; Ensure the mouse dosen't break minibuffer when I toggle between windows
(defun my-stop-using-minibuffer ()
  "kill the minibuffer"
  (when (and (>= (recursion-depth) 1) (active-minibuffer-window))
    (abort-recursive-edit)))

(add-hook 'mouse-leave-buffer-hook 'my-stop-using-minibuffer)


;; Spellcheck overrides my bindings, use the bind-keys package to ensure they work globally
(require 'bind-key)

(bind-keys*
 ("C-." . my-next-window)
 ("C-," . my-prev-window))

(defun my-next-window ()
  (interactive)
  (other-window 1))

(defun my-prev-window ()
  (interactive)
  (other-window -1))


;;----------------------------------------------------------------------------
;; Editor and environment config
;;----------------------------------------------------------------------------

(setq display-line-numbers-type 'relative)

;; Always spellcheck
(add-hook 'text-mode-hook 'flyspell-mode)
(add-hook 'prog-mode-hook 'flyspell-prog-mode)

;; The default imenu shortcut conflicts with both the spellcheck and my custom mappings
;; Remap imenu to C-i (which makes more sense anyway)
(global-set-key (kbd "C-i") 'imenu)


;; Use S-s to search for all occurrences of the last isearch in the current project
;; (define-key projectile-mode-map (kbd "s-s") 'rg-isearch-project)

;; Use S-s to search the whole project for a string (using isearch for interactivity)
;; Note: rg-project is very similar. However, this approach allows for interactive highlighting and removes an additional dialog box
(define-key projectile-mode-map (kbd "s-s") '(lambda () (interactive)(isearch-forward)(rg-isearch-project)))

;; Open buffers in sane way; only split the screen vertically if there's no horizontal room left
;; https://emacs.stackexchange.com/questions/20492/how-can-i-get-a-sensible-split-window-policy
(setq split-height-threshold 120
      split-width-threshold 160)

(defun my-split-window-sensibly (&optional window)
  "replacement `split-window-sensibly' function which prefers vertical splits"
  (interactive)
  (let ((window (or window (selected-window))))
    (or (and (window-splittable-p window t)
             (with-selected-window window
               (split-window-right)))
        (and (window-splittable-p window)
             (with-selected-window window
               (split-window-below))))))

(setq split-window-preferred-function #'my-split-window-sensibly)


;;----------------------------------------------------------------------------
;; Automatically enable dired sidebar when interacting with projects
;;----------------------------------------------------------------------------

(require 'dired-sidebar)

;; (add-hook 'dired-sidebar-mode-hook
;;           (lambda ()
;;             (unless (file-remote-p default-directory)
;;               (auto-revert-mode))))

(push 'toggle-window-split dired-sidebar-toggle-hidden-commands)
(push 'rotate-windows dired-sidebar-toggle-hidden-commands)

(setq dired-sidebar-use-term-integration t)
(setq dired-sidebar-use-custom-font t)
(setq desktop-save-mode 0)

(add-hook 'projectile-after-switch-project-hook 'dired-sidebar-show-sidebar)
