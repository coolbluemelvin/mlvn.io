---
title: "Hugo, Wercker and Github Pages"
date: 2019-03-02T19:15:26+01:00
toc: true
tags:
  - ci/cd
  - hugo
  - Github
  - wercker
  - codacy
---

Recently I've started using Hugo to build my personal homepage and blog while serving it using Github Pages. First I started out by updating my Github Pages repository using a deploy script within the Hugo file repository. Of course that's not the way to go so instead I've been building a deployment pipeline using [Wercker](https://app.wercker.com/melvincornelissen/mlvn.io/installing/).

# Prerequisites

- Github Repository for the Hugo files
- Github Repository for the Github page (username.github.io)
- [Github personal access token](https://github.com/settings/tokens)
- [Wercker](https://app.wercker.com/) account

## Optional

- [Codacy](https://www.codacy.com/) account

# Deployment

The wercker.yml file:
```yaml
box: debian
build:
    # Steps make up the actions in your pipeline
    # Read more about steps on our dev center:
    # https://devcenter.wercker.com/development/steps/

  steps:
    - install-packages:
        packages: git
    - script:
        name: download hugo theme
        cwd: themes/
        code: git clone https://github.com/rhazdon/hugo-theme-hello-friend-ng.git hello-friend-ng
    - arjen/hugo-build:
        basedir: "/"
        version: "0.53"
        theme: hello-friend-ng
        flags: --buildDrafts=true

deploy:
  steps:
    - melvincornelissen/gh-pages:
        token: $GIT_TOKEN
        domain: mlvn.io
        repo: coolbluemelvin/coolbluemelvin.github.io
        path: public
```

{{< figure src="/images/wercker.png" alt="wercker" position="center" style="border-radius: 8px;" >}}

{{< figure src="/images/wercker-build.png" alt="wercker-build" position="center" style="border-radius: 8px;" >}}

{{< figure src="/images/wercker-deploy.png" alt="wercker-deploy" position="center" style="border-radius: 8px;" >}}

{{< figure src="/images/codacy.png" alt="codacy" position="center" style="border-radius: 8px;" >}}

{{< figure src="/images/codacy-checks.png" alt="codacy-checks" position="center" style="border-radius: 8px;" >}}

{{< figure src="/images/codacy-overview.png" alt="codacy-overview" position="center" style="border-radius: 8px;" >}}
