---
title: Playing with Probabilities
---

<h1 id="the-header">The Header</h1>
<p>Imports, pragmas, and the module declaration</p>
<pre><font color=Cyan>&gt;</font> <font color=Blue><i>{-# LANGUAGE TupleSections #-}</i></font>
<font color=Cyan>&gt;</font> <font color=Green><u>module</u></font> MDists <font color=Green><u>where</u></font>
<font color=Cyan>&gt;</font> <font color=Green><u>import</u></font> Data<font color=Cyan>.</font>Map <font color=Cyan>(</font>Map<font color=Cyan>,</font> <font color=Cyan>(</font><font color=Cyan>!</font><font color=Cyan>)</font><font color=Cyan>)</font>
<font color=Cyan>&gt;</font> <font color=Green><u>import</u></font> <font color=Green><u>qualified</u></font> Data<font color=Cyan>.</font>Map <font color=Green><u>as</u></font> M
<font color=Cyan>&gt;</font> <font color=Green><u>import</u></font> Data<font color=Cyan>.</font>Function
<font color=Cyan>&gt;</font> <font color=Green><u>import</u></font> Data<font color=Cyan>.</font>List
<font color=Cyan>&gt;</font> <font color=Green><u>import</u></font> Data<font color=Cyan>.</font>Ratio
</pre>
 
<h1 id="the-code">The Code</h1>
<pre><font color=Cyan>&gt;</font> <font color=Green><u>type</u></font> P <font color=Red>=</font> Rational
<font color=Cyan>&gt;</font> <font color=Green><u>type</u></font> PDist a <font color=Red>=</font> Map a P
</pre>
<p>Hypotheses are getting represented as probability distributions with a probability attached to them</p>
<pre><font color=Cyan>&gt;</font> <font color=Green><u>data</u></font> Hypothesis a <font color=Red>=</font> H <font color=Cyan>{</font>conditionals <font color=Red>::</font> PDist a<font color=Cyan>,</font>
<font color=Cyan>&gt;</font>                          chance <font color=Red>::</font> P<font color=Cyan>}</font> <font color=Green><u>deriving</u></font> <font color=Cyan>(</font>Show<font color=Cyan>)</font>
</pre>
<p>Next, the distribution over hypotheses - let’s make strings our labels, just because strings are easy to use</p>
<pre><font color=Cyan>&gt;</font> <font color=Green><u>data</u></font> HDist a <font color=Red>=</font> HD <font color=Cyan>{</font>hps <font color=Red>::</font> Map String <font color=Cyan>(</font>Hypothesis a<font color=Cyan>)</font><font color=Cyan>}</font> <font color=Green><u>deriving</u></font> <font color=Cyan>(</font>Show<font color=Cyan>)</font>
</pre>
 
<h3 id="helpers">Helpers</h3>
<p>First, we want to implement a few basic funcitons that will allow the rest of these to work nicely For example, we’ll want to be able to apply some function <span class="math">[0, 1] → [0, 1]</span> to the probabilities we’re juggling here</p>
<pre><font color=Cyan>&gt;</font> <font color=Blue>applyToProbability</font> <font color=Red>::</font> <font color=Cyan>(</font>P <font color=Red>-&gt;</font> P<font color=Cyan>)</font> <font color=Red>-&gt;</font> Hypothesis a <font color=Red>-&gt;</font> Hypothesis a
<font color=Cyan>&gt;</font> <font color=Blue>applyToProbability</font> f <font color=Cyan>(</font>H d p<font color=Cyan>)</font> <font color=Red>=</font> H d <font color=Cyan>$</font> f p
</pre>
<p>That one’s pretty simple, but on its own not that useful. Instead, let’s wrap it up so we don’t have to deal with the individual hypotheses - instead, we’ll map it over a the hypothesis distribution</p>
<pre><font color=Cyan>&gt;</font> <font color=Blue>applyToProbs</font> <font color=Red>::</font> <font color=Cyan>(</font>P <font color=Red>-&gt;</font> P<font color=Cyan>)</font> <font color=Red>-&gt;</font> HDist a <font color=Red>-&gt;</font> HDist a
<font color=Cyan>&gt;</font> <font color=Blue>applyToProbs</font> f <font color=Cyan>(</font>HD hps<font color=Cyan>)</font> <font color=Red>=</font> HD <font color=Cyan>$</font> M<font color=Cyan>.</font>map <font color=Cyan>(</font>applyToProbability f<font color=Cyan>)</font> hps
</pre>
<p>Now, the main reason we’re defining those two functions is to write a function <code>renormalize</code> that takes a distribution and makes sure the probabilities actually sum to 1 without changing any of the ratios between probabilities</p>
<pre><font color=Cyan>&gt;</font> <font color=Blue>renormalize</font> <font color=Red>::</font> HDist a <font color=Red>-&gt;</font> HDist a
<font color=Cyan>&gt;</font> <font color=Blue>renormalize</font> h<font color=Red>@</font><font color=Cyan>(</font>HD dist<font color=Cyan>)</font> <font color=Red>=</font> applyToProbs <font color=Cyan>(</font><font color=Cyan>/</font>normalizer<font color=Cyan>)</font> h
<font color=Cyan>&gt;</font>   <font color=Green><u>where</u></font> normalizer <font color=Red>=</font> M<font color=Cyan>.</font>foldl' <font color=Cyan>(</font><font color=Cyan>+</font><font color=Cyan>)</font> <font color=Magenta>0</font> <font color=Cyan>.</font> M<font color=Cyan>.</font>map chance <font color=Cyan>$</font> dist
</pre>
<p>Our basic guess function is just a small wrapper around M.lookup - it fetches the likelihood of a hypothesis on its identifier If we don’t have a hypothesis in our distribution, it assigns it a probability of 0, but otherwise just fetches the probability from the hypothesis</p>
<pre><font color=Cyan>&gt;</font> <font color=Blue>guess</font> <font color=Red>::</font> Ord a <font color=Red>=&gt;</font> HDist a <font color=Red>-&gt;</font> String <font color=Red>-&gt;</font> P
<font color=Cyan>&gt;</font> <font color=Blue>guess</font> <font color=Cyan>(</font>HD hps<font color=Cyan>)</font> str <font color=Red>=</font> <font color=Green><u>case</u></font> M<font color=Cyan>.</font>lookup str hps <font color=Green><u>of</u></font> Nothing <font color=Red>-&gt;</font> <font color=Magenta>0</font>
<font color=Cyan>&gt;</font>                                               Just h <font color=Red>-&gt;</font> chance h
</pre>
 
<h3 id="updating">Updating!</h3>
<p>Now, our not-so-secret goal here was to model Bayesian updates If you’re not familiar with Bayes’ Theorem, here it is:</p>
<p><span class="math">$$p(H|D)=p(D|H)\frac{p(H)}{p(D)}$$</span></p>
<p>To explain: the probability of a hypothesis being true, on some data, is the probability of that data given the hypothesis (<span class="math"><em>p</em>(<em>D</em>∣<em>H</em>)</span>) multiplied by the probability we had previously assigned the hypothesis (our “prior”, or <span class="math"><em>p</em>(<em>H</em>)</span>), then divided by the probability of that data under all hypotheses (<span class="math"><em>p</em>(<em>D</em>)</span>). We don’t deal directly with the probability of the data under all hypotheses - instead preferring to renormalize the distribution after the fact</p>
<p>Of course, we want to automate this adjustment. The first step is to multiply each probability by the numerator - <span class="math"><em>p</em>(<em>D</em>∣<em>H</em>) ⋅ <em>p</em>(<em>H</em>)</span></p>
<pre><font color=Cyan>&gt;</font> <font color=Blue>pAndCond</font> <font color=Red>::</font> Ord a <font color=Red>=&gt;</font> a <font color=Red>-&gt;</font> Hypothesis a <font color=Red>-&gt;</font> Hypothesis a
<font color=Cyan>&gt;</font> <font color=Blue>pAndCond</font> event <font color=Cyan>(</font>H dist prior<font color=Cyan>)</font> <font color=Red>=</font> H dist <font color=Cyan>$</font> prior <font color=Cyan>*</font> likelihood
<font color=Cyan>&gt;</font>   <font color=Green><u>where</u></font> likelihood <font color=Red>=</font> M<font color=Cyan>.</font>findWithDefault <font color=Magenta>0</font> event dist
</pre>
<p>With that done, we just renormalize, effecitvely dividing by <span class="math"><em>p</em>(<em>D</em>)</span> We know this works because if we divided by anything other than the renormalizer, the ending probabilities would sum to some number <em>other than 1</em>, so, on pain of contradiction, <br> <span class="math"><em>p</em>(<em>D</em>) = </span><code>renormalizer</code></p>
<pre><font color=Cyan>&gt;</font> <font color=Blue>updateOnEvent</font> <font color=Red>::</font> Ord a <font color=Red>=&gt;</font> HDist a <font color=Red>-&gt;</font> a <font color=Red>-&gt;</font> HDist a
<font color=Cyan>&gt;</font> <font color=Blue>updateOnEvent</font> <font color=Cyan>(</font>HD dist<font color=Cyan>)</font> event <font color=Red>=</font> renormalize <font color=Cyan>.</font> HD <font color=Cyan>.</font> M<font color=Cyan>.</font>map <font color=Cyan>(</font>pAndCond event<font color=Cyan>)</font> <font color=Cyan>$</font> dist
</pre>
<p>Of course, we want to be able to update on a series of events, so we fold over a list of events This fold ends up being fully strict, so instead of a foldr we use <code>foldl'</code> (hooray tail recursion!)</p>
<pre><font color=Cyan>&gt;</font> <font color=Blue>update</font> <font color=Red>::</font> Ord b <font color=Red>=&gt;</font> HDist b <font color=Red>-&gt;</font> <font color=Red>[</font>b<font color=Red>]</font> <font color=Red>-&gt;</font> HDist b
<font color=Cyan>&gt;</font> <font color=Blue>update</font> <font color=Red>=</font> foldl' updateOnEvent
</pre>
 
<h3 id="construction-helpers">Construction helpers</h3>
<p>We’ll use these utilities to construct and solve some toy problems a little further down First, a few more helpers that’ll be really important for constructing the toy problems</p>
<p>This one just normalizes a hypothesis, so we can think of it in terms of allocating odds instead of probabilities</p>
<pre><font color=Cyan>&gt;</font> <font color=Blue>normalizeHyp</font> <font color=Red>::</font> Hypothesis a <font color=Red>-&gt;</font> Hypothesis a
<font color=Cyan>&gt;</font> <font color=Blue>normalizeHyp</font> <font color=Cyan>(</font>H m p<font color=Cyan>)</font> <font color=Red>=</font> <font color=Green><u>if</u></font> totalP <font color=Cyan>==</font> <font color=Magenta>1</font> <font color=Green><u>then</u></font> <font color=Cyan>(</font>H m p<font color=Cyan>)</font> <font color=Green><u>else</u></font> H <font color=Cyan>(</font>M<font color=Cyan>.</font>map <font color=Cyan>(</font><font color=Cyan>/</font>totalP<font color=Cyan>)</font> m<font color=Cyan>)</font> p
<font color=Cyan>&gt;</font>   <font color=Green><u>where</u></font> totalP <font color=Red>=</font> M<font color=Cyan>.</font>foldl' <font color=Cyan>(</font><font color=Cyan>+</font><font color=Cyan>)</font> <font color=Magenta>0</font> m
</pre>
<p>Next, this one just makes a hypothesis distribution from a list</p>
<pre><font color=Cyan>&gt;</font> <font color=Blue>fromList</font> <font color=Red>::</font> <font color=Red>[</font><font color=Cyan>(</font>String<font color=Cyan>,</font> Hypothesis a<font color=Cyan>)</font><font color=Red>]</font> <font color=Red>-&gt;</font> HDist a
<font color=Cyan>&gt;</font> <font color=Blue>fromList</font> <font color=Red>=</font> renormalize <font color=Cyan>.</font> HD <font color=Cyan>.</font> M<font color=Cyan>.</font>fromList
</pre>
<h1 id="toy-problems">
Toy Problems
</h1>

<h3 id="monty-hall">
Monty Hall
</h3>
<p>We’ll start out by getting a list of doors</p>
<pre><font color=Cyan>&gt;</font> <font color=Blue>drs</font> <font color=Red>=</font> <font color=Magenta>"abc"</font>
</pre>
<p>Next, our function for generating a hypothesis for which door gets opened based on our guess and the correct answer</p>
<pre><font color=Cyan>&gt;</font> <font color=Blue>isIn</font> <font color=Red>::</font> Char <font color=Red>-&gt;</font> Char <font color=Red>-&gt;</font> Hypothesis Char
<font color=Cyan>&gt;</font> <font color=Blue>isIn</font> guess correct <font color=Red>=</font> normalizeHyp <font color=Cyan>.</font> flip H <font color=Magenta>1</font> <font color=Cyan>.</font> M<font color=Cyan>.</font>fromList <font color=Cyan>$</font>
<font color=Cyan>&gt;</font>                      <font color=Red>[</font><font color=Cyan>(</font>dr<font color=Cyan>,</font><font color=Magenta>1</font><font color=Cyan>)</font> <font color=Red>|</font> dr <font color=Red>&lt;-</font> drs<font color=Cyan>,</font> dr <font color=Cyan>/=</font> guess<font color=Cyan>,</font> dr <font color=Cyan>/=</font> correct<font color=Red>]</font>
</pre>
<p>And, finally, the problem itself! The identifiers are each just the single character name of the door (a, b, or c) The hypotheses are each generated assuming the identifier is the correct door according to the isIn function</p>
<pre><font color=Cyan>&gt;</font> <font color=Blue>montyHall</font> <font color=Red>::</font> Char <font color=Red>-&gt;</font> HDist Char
<font color=Cyan>&gt;</font> <font color=Blue>montyHall</font> guess <font color=Red>=</font> fromList <font color=Red>[</font><font color=Cyan>(</font><font color=Red>[</font>dr<font color=Red>]</font><font color=Cyan>,</font>isIn guess dr<font color=Cyan>)</font> <font color=Red>|</font> dr <font color=Red>&lt;-</font> drs<font color=Red>]</font>
</pre>
<pre><font color=Cyan>&gt;</font> <font color=Blue>shouldYouSwitch</font> <font color=Red>=</font> guess <font color=Cyan>(</font>update <font color=Cyan>(</font>montyHall <font color=Magenta>'a'</font><font color=Cyan>)</font> <font color=Magenta>"b"</font><font color=Cyan>)</font> <font color=Magenta>"a"</font> <font color=Cyan>&lt;</font> <font color=Magenta>1</font> <font color=Cyan>%</font> <font color=Magenta>2</font>
</pre>
<p>And there you go! The boolean <code>shouldYouSwitch</code> starts from you picking door a, then Monty opens b, and checks if you have worse than even chances of it being behind a</p>
<h3 id="cookies">
Cookies
</h3>

<p>We’ve got two bools of chocolate and vanilla cookies The first bowl is three quarters vanilla and one quarter chocolate, while the other is half and half</p>
<pre><font color=Cyan>&gt;</font> <font color=Blue>bowl1</font> <font color=Red>=</font> normalizeHyp <font color=Cyan>$</font> flip H <font color=Magenta>1</font> <font color=Cyan>$</font> M<font color=Cyan>.</font>fromList <font color=Red>[</font><font color=Cyan>(</font><font color=Magenta>'v'</font><font color=Cyan>,</font><font color=Magenta>3</font><font color=Cyan>)</font><font color=Cyan>,</font><font color=Cyan>(</font><font color=Magenta>'c'</font><font color=Cyan>,</font><font color=Magenta>1</font><font color=Cyan>)</font><font color=Red>]</font>
<font color=Cyan>&gt;</font> <font color=Blue>bowl2</font> <font color=Red>=</font> normalizeHyp <font color=Cyan>$</font> flip H <font color=Magenta>1</font> <font color=Cyan>$</font> M<font color=Cyan>.</font>fromList <font color=Red>[</font><font color=Cyan>(</font>a<font color=Cyan>,</font><font color=Magenta>1</font><font color=Cyan>)</font> <font color=Red>|</font> a <font color=Red>&lt;-</font> <font color=Magenta>"vc"</font><font color=Red>]</font>
</pre>
<p>Next we’ll make a distribution from both the bowls</p>
<pre><font color=Cyan>&gt;</font> <font color=Blue>bowls</font> <font color=Red>=</font> fromList  <font color=Red>[</font><font color=Cyan>(</font><font color=Magenta>"b1"</font><font color=Cyan>,</font>bowl1<font color=Cyan>)</font><font color=Cyan>,</font><font color=Cyan>(</font><font color=Magenta>"b2"</font><font color=Cyan>,</font>bowl2<font color=Cyan>)</font><font color=Red>]</font>
</pre>
<p>From this, given a stream of cookies, it’ll guess the chance you were drawing from one of the bowls</p>
<h3 id="m&amp;m">
M&amp;M’s
</h3>

<p>Some background: The mixture of M&amp;M’s has been changed a few times In 1995, blue M&amp;M’s were introduced Given a bundle of M&amp;M’s, what’s the probability it came from a 1994 mix vs a 1996 mix?</p>
<table border = "1">
<tr> <td> 
color
</td> <td> 
percentage in ’94
</td> <td> 
percentage in ’96
</td> </tr>
<tr> <td> 
brown
</td> <td> 
30
</td> <td> 
24
</td> </tr>
<tr> <td> 
green
</td> <td> 
10
</td> <td> 
20
</td> </tr>
<tr> <td> 
orange
</td> <td> 
10
</td> <td> 
16
</td> </tr>
<tr> <td> 
yellow
</td> <td> 
20
</td> <td> 
14
</td> </tr>
<tr> <td> 
red
</td> <td> 
20
</td> <td> 
13
</td> </tr>
<tr> <td> 
tan
</td> <td> 
10
</td> <td> 
0
</td> </tr>
<tr> <td> 
blue
</td> <td> 
0
</td> <td> 
13
</td> </tr>
</table>

<p>Now, let’s encode that into hypotheses</p>
<pre><font color=Cyan>&gt;</font> <font color=Blue>mix94</font> <font color=Red>=</font> normalizeHyp <font color=Cyan>.</font> flip H <font color=Magenta>1</font> <font color=Cyan>$</font> M<font color=Cyan>.</font>fromList
<font color=Cyan>&gt;</font>         <font color=Red>[</font><font color=Cyan>(</font><font color=Magenta>"brown"</font><font color=Cyan>,</font><font color=Magenta>30</font><font color=Cyan>)</font><font color=Cyan>,</font><font color=Cyan>(</font><font color=Magenta>"green"</font><font color=Cyan>,</font><font color=Magenta>10</font><font color=Cyan>)</font><font color=Cyan>,</font><font color=Cyan>(</font><font color=Magenta>"orange"</font><font color=Cyan>,</font><font color=Magenta>10</font><font color=Cyan>)</font><font color=Cyan>,</font><font color=Cyan>(</font><font color=Magenta>"yellow"</font><font color=Cyan>,</font><font color=Magenta>20</font><font color=Cyan>)</font><font color=Cyan>,</font><font color=Cyan>(</font><font color=Magenta>"red"</font><font color=Cyan>,</font><font color=Magenta>20</font><font color=Cyan>)</font><font color=Cyan>,</font><font color=Cyan>(</font><font color=Magenta>"tan"</font><font color=Cyan>,</font><font color=Magenta>10</font><font color=Cyan>)</font><font color=Red>]</font>
</pre>
<pre><font color=Cyan>&gt;</font> <font color=Blue>mix96</font> <font color=Red>=</font> normalizeHyp <font color=Cyan>.</font> flip H <font color=Magenta>1</font> <font color=Cyan>$</font> M<font color=Cyan>.</font>fromList
<font color=Cyan>&gt;</font>         <font color=Red>[</font><font color=Cyan>(</font><font color=Magenta>"brown"</font><font color=Cyan>,</font><font color=Magenta>24</font><font color=Cyan>)</font><font color=Cyan>,</font><font color=Cyan>(</font><font color=Magenta>"green"</font><font color=Cyan>,</font><font color=Magenta>20</font><font color=Cyan>)</font><font color=Cyan>,</font><font color=Cyan>(</font><font color=Magenta>"orange"</font><font color=Cyan>,</font><font color=Magenta>16</font><font color=Cyan>)</font><font color=Cyan>,</font><font color=Cyan>(</font><font color=Magenta>"yellow"</font><font color=Cyan>,</font><font color=Magenta>14</font><font color=Cyan>)</font><font color=Cyan>,</font><font color=Cyan>(</font><font color=Magenta>"red"</font><font color=Cyan>,</font><font color=Magenta>13</font><font color=Cyan>)</font><font color=Cyan>,</font><font color=Cyan>(</font><font color=Magenta>"blue"</font><font color=Cyan>,</font><font color=Magenta>13</font><font color=Cyan>)</font><font color=Red>]</font>
</pre>
<p>And, finally, our hypothesis distribution</p>
<pre><font color=Cyan>&gt;</font> <font color=Blue>bag</font> <font color=Red>=</font> fromList <font color=Red>[</font><font color=Cyan>(</font><font color=Magenta>"94"</font><font color=Cyan>,</font>mix94<font color=Cyan>)</font><font color=Cyan>,</font><font color=Cyan>(</font><font color=Magenta>"96"</font><font color=Cyan>,</font>mix96<font color=Cyan>)</font><font color=Red>]</font>
</pre>

