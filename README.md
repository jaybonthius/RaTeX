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

## Why use RaTeX instead of MathJaX?

1. _No Javascript._ Like anything rendered on the client's side with JavaScript, there's a start-up time tax. As of MathJax 3.0, that wait is brief (and with KaTeX, even briefer) but the more math on the page, the more noticeable the wait.

2. _Full LaTeX functionality_. There are only a subset of LaTeX commands and environments to choose from. That's not a failing of MathJax—it was only ever meant to handle inline and display math.

3. _More fonts._ As of MathJax 3.0, there's only one available font. This doesn't matter much for mathematical text, but if you frequently include regular text with `\text{...}`, it won't match your body text. With RaTeX, you can use any font you want.

## How it works

## How to use
