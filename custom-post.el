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
;; Remap imenu to s-i (which makes more sense anyway)
(global-set-key (kbd "s-i") 'imenu)  ;;; Ahhh!!! C-i === <tab>???!

;; Use S-s to search for all occurrences of the last isearch in the current project
;; (define-key projectile-mode-map (kbd "s-s") 'rg-isearch-project)

;; Use S-s to search the whole project for a string (using isearch for interactivity)
;; Note: rg-project is very similar. However, this approach allows for interactive highlighting and removes an additional dialog box
(define-key projectile-mode-map (kbd "s-s") '(lambda () (interactive)(isearch-forward)(rg-isearch-project)))
(define-key projectile-mode-map (kbd "s-f") 'projectile-find-file)

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
;; Automatically enable treemacs when interacting with projects
;;----------------------------------------------------------------------------

(add-hook 'projectile-after-switch-project-hook 'my-display-treemacs-workaround)  ;; really this should just be: 'treemacs-add-and-display-current-project)
(add-hook 'projectile-find-file-hook 'my-display-treemacs-then-focus-other)

(defun my-display-treemacs-workaround ()
  "Ensure treemacs instance starts and renders with project"
  (interactive)
  (my-display-treemacs-then-focus-other)
  (run-at-time 0.05 nil 'my-display-treemacs-then-focus-other)  ;; Absolutely awful hack to combat race condition
  )

(defun my-display-treemacs-then-focus-other ()
  "opens treemacs without leaving the existing window (this may not be reliable with multiple windows)"
  (interactive)
  (treemacs-add-and-display-current-project)
  ;; (treemacs-select-window)
  (next-window-any-frame))

;;----------------------------------------------------------------------------
;; Default config doesn't work well in text mode, lets fix that
;;----------------------------------------------------------------------------

;; Show line number
(add-hook 'text-mode-hook 'display-line-numbers-mode)

;; Make tab/ backtab behave like a modern editor
;; https://stackoverflow.com/questions/2249955/emacs-shift-tab-to-left-shift-the-block
(defun my-indent-region-custom(numSpaces)
  (progn
                                        ; default to start and end of current line
    (setq regionStart (line-beginning-position))
    (setq regionEnd (line-end-position))
                                        ; if there's a selection, use that instead of the current line
    (when (use-region-p)
      (setq regionStart (region-beginning))
      (setq regionEnd (region-end))
      )

    (save-excursion ; restore the position afterwards
      (goto-char regionStart) ; go to the start of region
      (setq start (line-beginning-position)) ; save the start of the line
      (goto-char regionEnd) ; go to the end of region
      (setq end (line-end-position)) ; save the end of the line

      (indent-rigidly start end numSpaces) ; indent between start and end
      (setq deactivate-mark nil) ; restore the selected region
      )
    )
  )

(defun my-untab-region (N)
  (interactive "p")
  (my-indent-region-custom -4)
  )

(defun my-tab-region (N)
  (interactive "p")
  (if (active-minibuffer-window)
      (minibuffer-complete)    ; tab is pressed in minibuffer window -> do completion
                                        ; else
    (if (string= (buffer-name) "*shell*")
        (comint-dynamic-complete) ; in a shell, use tab completion
                                        ; else
      (if (use-region-p)    ; tab is pressed is any other buffer -> execute with space insertion
          (my-indent-region-custom 4) ; region was selected, call indent-region
        (insert "    ") ; else insert four spaces as expected
        )))
  )

(define-key text-mode-map (kbd "<backtab>") 'my-untab-region)
(define-key text-mode-map (kbd "<tab>") 'my-tab-region)

;; custom-post.el ends here
