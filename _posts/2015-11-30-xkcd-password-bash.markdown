---
layout: post
category: bash
title: xkcd password generator
date: 2015-11-30 01:02:03
---

Tired of trying to figure out what password to generate?

Put this in your __.bashrc__ or __.zshrc__ and smoke it.

```bash
xkcd_password() {
  shuf -n5 /usr/share/dict/words | sed -e ':a;N;$!ba;s/\n/ /g;s/'\''//g;s/\b\(.\)/\u\1/g;s/ //g'
  }
```

```bash
~                                                                             ⍉
▶ xkcd_password 
DenunciationsVertebralForgersDimerGlum

~                                                                              
▶ 
```
