# My Book Template

This repository is a **starter template for writing books** using **Emacs Org-mode**, **LaTeX**, and **Pandoc**. It includes a clean folder structure, a publishing script, and a GitHub Actions workflow to automatically build your book in **PDF**, **EPUB**, and **HTML** formats.

---

## Repository Structure

```
.
├── .github/
│   └── workflows/
│       └── publish.yml       # GitHub Actions workflow to build the book automatically
├── chapters/                 # Optional subfiles for book chapters
│   ├── 01-introduction.org
│   └── ...
├── assets/                   # CSS, images, JS used in HTML output
│   ├── style.css
│   └── images/
│       └── example.png
├── book.org                  # Main Org file that includes chapters
├── publish.el                # Publishing script (PDF/EPUB/HTML)
└── README.md                 # This file
```

---

## How to Write Your Book

1. **Main file:** `book.org` is the entry point.
2. **Chapters:** Add new `.org` files under `chapters/` and include them in `book.org` like this:

```
#+INCLUDE: "chapters/01-introduction.org"
```

3. **Assets:** Place images, CSS, or JS in `assets/`. Only the HTML output uses these. PDF and EPUB embed images automatically.

---

## Building the Book Locally

Make sure you have the following installed:

* **Emacs** (28+ recommended)
* **LaTeX** (`texlive-full` recommended)
* **Pandoc**

Run the publishing script in batch mode:

```
emacs --batch -l publish.el -f book-publish-all
```

The outputs will appear in the `target/` folder:

```
target/
├── pdf/book.pdf
├── epub/book.epub
└── html/index.html
    └── assets/
```

---

## GitHub Actions

This template includes a **GitHub Actions workflow** (`.github/workflows/publish.yml`) that automatically builds your book whenever you push to the `main` branch.

It will:

1. Install Emacs, LaTeX, and Pandoc.
2. Run `publish.el` to build **PDF, EPUB, and HTML**.
3. Upload the `target/` folder as artifacts for download.

You can download the PDF, EPUB, or HTML directly from the workflow run artifacts.

---

## Customization

* **Book metadata:** Edit `book-title` and `book-author` in `publish.el`.
* **Output formatting:** Adjust LaTeX classes or Org export settings in `publish.el`.
* **HTML assets:** Update CSS or JS in `assets/` for custom HTML styling.

---

## Tips

* Keep chapters small and modular for easier editing.
* Use Org-mode links between chapters for cross-references.
* For HTML previews, open `target/html/index.html` in your browser.

---

## Quick Start for Contributors

1. Fork the repo.
2. Add or edit chapters in `chapters/`.
3. Add images or styling to `assets/`.
4. Run locally with:

```
emacs --batch -l publish.el -f book-publish-all
```

5. Commit changes — GitHub Actions will automatically rebuild the book.

---

This template is designed to make book publishing **clean, incremental, and easy for anyone** who wants to write a book in Org-mode.

---
