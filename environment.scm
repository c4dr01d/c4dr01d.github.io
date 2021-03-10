(use-modules (guix packages)
             (guix licenses)
             (guix build-system ruby)
             (gnu packages)
             (gnu packages ruby))
(package
  (name "jekyll-blog")
  (version "1.0")
  (source #f)
  (build-system ruby-build-system)
  (native-inputs
   `(("ruby-rspec" ,ruby-rspec)))
  (propagated-inputs
   `(("bundler" ,bundler)))
  (synopsis "A jekyll website")
  (description "My personal blog, powered by Jekyll and GNU Guix")
  (home-page "https://github.com/c4dr01d/c4dr01d.github.io")
  (license expat))
