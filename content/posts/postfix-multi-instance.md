---
title: "Postfix Multi Instance"
date: 2019-09-19T15:19:46+02:00
draft: true
---

# Postfix Multi instance solution

## Why?

I was challenged with finding a solution to split up our incoming mailflow and push it through separate content filters. As we're trying to split mails within the same domain we were unable to make this decision within a single postfix instance as it would only read a single transport map.

Therefore we've chosen to run multiple instances to make decisions based on a 1st and 2nd transport map. The reason we need two transport maps is because besides the content filter split we also use different applications as endpoints for certain mail addresses.

{{< figure src="/images/postfix-multi.png" alt="postfix-multi" position="center" style="border-radius: 6px;" >}}
