---
title: "Postfix Multi Instance"
date: 2019-09-19T15:19:46+02:00
draft: true
---

# Postfix Multi instance solution

## Why?

I was challenged with finding a solution to split up our incoming mailflow and push it through separate content filters. As we're trying to split mails within the same domain we were unable to make this decision within a single postfix instance as it would only read a single transport map.

Therefore we've chosen to run multiple instances to make decisions based on a 1st and 2nd transport map. The reason we need two transport maps is because besides the content filter split we also use different applications as endpoints for certain mail addresses.

## How?

First we need to enable postfix multi instance. We're calling the second instance postfix-delivery as that's what the main goal of the instance would be. We keep the initial postfix instance to decide which content filter the mail gets routed to.

```bash
####Initiate MultiInstance
postmulti -e init

####Create Secondary Instance postfix-delivery
postmulti -I postfix-deliver -e create

####Enable Secondary Instance
postmulti -i postfix-delivery -e enable
```

Next we need to configure the new instance's main and master configs. The main instance will run on port :25 and transports to the filters default ports. The filters will return the mail to the second instance on port :100025. This way we can transport mail based on two transport maps and have granularly control over which mail goes through which filter.

The first transport map would look like following:

```
firstmailaddress@domain.com         smtp:secondaryfilter.domain.com:25
secondmailaddress@otherdomain.com   smtp:secondaryfilter.domain.com:25
*                                   smtp:primaryfilter.domain.com:10024
```

{{< figure src="/images/postfix-multi.png" alt="postfix-multi" position="center" style="border-radius: 6px;" >}}
