---
title: "Hugo, Wercker and Github Pages"
date: 2019-03-02T19:15:26+01:00
toc: true
tags:
-   CI/CD
-   Hugo
-   Github
-   Wercker
-   Codacy
---

# From Hugo for Github Pages

Recently I've started using Hugo to build my personal homepage and blog while serving it using Github Pages. First I started out by updating my Github Pages repository using a deploy script within the Hugo file repository. Of course that's not the way to go so instead I've been building a deployment pipeline using [Wercker](https://app.wercker.com/melvincornelissen/mlvn.io/installing/).

## TL;DR

1.  Create [Github](https://github.com) repositories (Hugo & Github Pages).
2.  Install [Hugo](https://gohugo.io) in the Hugo repository.
3.  Add [Hugo](https://gohugo.io) repository to [Wercker](https://app.wercker.com).
    -   Add the [gh-pages](https://app.wercker.com/steps/melvincornelissen/gh-pages) to the deploy pipeline.
    -   Add the [Github personal access token](https://github.com/settings/tokens) to the deploy pipeline.
4.  Trigger a build by pushing a commit into the Hugo repository.


## Prerequisites

-   Github Repository for the Hugo files
-   Github Repository for the Github page (username.github.io)
-   [Github personal access token](https://github.com/settings/tokens)
-   [Wercker](https://app.wercker.com/) account

### Optional

-   Github Repository for the Wercker buildstep
-   [Codacy](https://www.codacy.com/) account

## Wercker build step

Within Wercker there are several build steps already created which you can use for deploying to Github Pages. I however decided to build my own based on uetchy/gh-pages in order to have more control over the script actually running the deployment. You'll need a Github Repository with the following files to build and deploy your own build steps.

-   run.sh
-   step.yml
-   wercker.yml

The `run.sh` will contain the script performing the deployment to Github Pages, `step.yml` contains the build step specific information like the name and all properties and last the `wercker.yml` file contains the build and deployment steps for the build step itself. The `wercker.yml` eventually pushes the step into the "Steps Store" in Wercker.

In case you're interested, my build step can be found in this [Github Repository](https://github.com/coolbluemelvin/wercker-step-gh-pages)

## Deployment

The wercker.yml file:
```yaml
box: debian
build:
    # Steps make up the actions in your pipeline
    # Read more about steps on our dev center:
    # https://devcenter.wercker.com/development/steps/

  steps:
    - install-packages:
        packages: git curl
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
    - install-packages:
        packages: git curl
    - melvincornelissen/gh-pages:
        token: $GIT_TOKEN
        domain: mlvn.io
        repo: coolbluemelvin/coolbluemelvin.github.io
        path: public
```

{{< figure src="/images/wercker.png" alt="wercker" position="center" style="border-radius: 6px;" >}}

{{< figure src="/images/wercker-build.png" alt="wercker-build" position="center" style="border-radius: 6px;" >}}

{{< figure src="/images/wercker-deploy.png" alt="wercker-deploy" position="center" style="border-radius: 6px;" >}}

{{< figure src="/images/codacy.png" alt="codacy" position="center" style="border-radius: 6px;" >}}

{{< figure src="/images/codacy-checks.png" alt="codacy-checks" position="center" style="border-radius: 6px;" >}}

{{< figure src="/images/codacy-overview.png" alt="codacy-overview" position="center" style="border-radius: 6px;" >}}
