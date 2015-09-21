---
title: Exporting Literate Haskell With HSColour and Pandoc
---

<p>In <a href="http://blog.gallabytes.com/2014/03/isomorphism-equality-pq-and-other-ways.html">yesterday's post</a> I said I would detail the workflow from literate Haskell + markdown to postable html, so here we go:</p>
<p>Requirements: You need to have Haskell installed somehow. I generally recommend the <a href="http://www.haskell.org/platform/">Haskell Platform</a> installed through your OS's package manager (<code>pacman</code>, <code>apt-get</code>, <code>homebrew</code>...). At a minimum, you need ghc and cabal-install Next, you need hscolour and pandoc installed. If you already have them, great! If not, run these commands:</p>
<blockquote>
<p>cabal install hscolour <br /> cabal install pandoc</p>
</blockquote>
Once you have those installed, it's relatively simple - just run this script:
<script src="https://gist.github.com/GallagherCommaJack/9531391.js"></script>

<p>There you go! Now you've highlighted the code bits, and left the rest to be formatted as markdown!</p>
