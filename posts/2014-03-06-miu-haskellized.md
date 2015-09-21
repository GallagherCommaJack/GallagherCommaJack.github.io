---
title: MIU Haskellized
---

Note: crosspost from <a href="http://godellog.blogspot.com/2014/02/miu-haskellized.html">here</a>, I originally planned to keep that blog separate but on thinking more about it I realized that's stupid.<br />
<br />
One of the first formal systems that Hofstadter introduces in the book is the so-called <a href="https://en.wikipedia.org/wiki/MU_puzzle">MIU system</a>.  It consists of four rules that can be used to transform a string of M's, I's, and U's: <br />
Add a U to the end of any string ending in I. For example: MI to MIU. <br />
Double the string after the M (that is, change Mx, to Mxx). For example: MIU to MIUIU. <br />
Replace any III with a U. For example: MUIIIU to MUUU. <br />
Remove any UU. For example: MUUU to MU. <br />
<ol>
<li>MU contains no I's
</li>
<li>MU contains no I's
</li>
<li>Lemma: You can only eliminate all I's from a string if the number of I's is a multiple of three
<ul>
<li>the only way to remove I's is to convert them to U's
</li>
<li>I's can only be converted to U's in groups of 3
</li>
<li>∴ You can only eliminate all I's if the number of I's ≡ 0 (mod 3)
</li>
</ul>
</li>
<li>Lemma: There is no string of multiplications by 2 and subtractions of 3
<ul>
<li>∀ x. x - 3 ≡ x (mod 3)
</li>
<li>0 * 2 ≡ 0 (mod 3)
</li>
<li>1 * 2 ≡ 2 (mod 3)
</li>
<li>2 * 2 ≡ 1 (mod 3)
</li>
<li>∴ by exhaustion, there is no string of multiplications by 2 and subtractions of 3 that will generate a multiple of 3
</li>
</ul>
</li>
<li>∴ There is no combination of rule applications that will eliminate all I's from a string
</li>
<li>∴ MU is underivable in the MIU system
</li>
</ol>
Anyway, here's my code for manipulating MIU strings.  Have fun! <br />
<script src="https://gist.github.com/GallagherCommaJack/9125933.js"></script>
