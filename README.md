# RaTeX 🐀

A Racket-based (Pollen-based) alternative to MathJaX that brings full-fat LaTeX to the web. No Javascript required!

## Requirements

- A [Pollen](https://docs.racket-lang.org/pollen/)-based website
- The [`uuid`](https://docs.racket-lang.org/uuid/index.html) Racket package (`raco pkg install uuid`)

## Installation

1. Download `ratex.rkt` and place in the same directory as `pollen.tex`.

2. In `pollen.tex` file, paste the following lines near the top:

   ```
   (require "racotex.rkt")
   (provide (all-from-out "racotex.rkt"))
   ```

## How it works

Blah blah blah

## How to use
