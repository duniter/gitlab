First a gitlab runner must be configured. [todo link]

# Create the repository locally by github duplication
This must be realized using a user that is connected in gitlab with github.(todo link connecttogitlab)

Choose "New project".

![](images/SynchronizeToGithub-12ac0dcb.png)

Click "import project from > github"
![](images/SynchronizeToGithub-55a31b4d.png)

Authorize your user connected with gitlab to do the import
![](images/SynchronizeToGithub-b4aeee68.png)

In the project you want to import, select the proper group you want this project be part of and then click on import.

![](images/SynchronizeToGithub-c3ab82bd.png)

# Automatically push to github at any push on gitlab
## Dedicated user
Create a dedicated user in github for this.

Invite him to the github project.
![](images/SynchronizeToGithub-6893754c.png)

As this user, accept the invitation.
![](images/SynchronizeToGithub-13b53256.png)
![](images/SynchronizeToGithub-d63304c7.png)


## Lock all branches on github
Except for the gitlab dedicated user.
![](images/SynchronizeToGithub-1bf81363.png)

## Gitlab secret variable
### Create an api secret key
For the dedicated user, in the settings page, create an api key
![](images/SynchronizeToGithub-384b5820.png)

### Create a secret key variable in gitlab
Create a secret variable in gitlab with this secret key
![](images/SynchronizeToGithub-d0d05b8a.png)

Adress must be built that way:
```
https://user:secret-api-key@github.com/group/project
```

### .gitlab-ci.yml configuration
Create in the repository a `.gitlab-ci.yml` file with content:

```
stages:
    - github-sync

push_to_github:
    stage: github-sync
    variables:
        GIT_STRATEGY: none
    script:
        - rm -rf ./*
        - rm -rf .git
        - git clone --mirror $CI_REPOSITORY_URL .
        - git remote add github $GITHUB_URL_AND_KEY
        - git config --global user.email "contact@duniter.org"
        - git config --global user.name "Duniter"
        # Job would fail if we don't remove refs about pull requests
        - bash -c "cat packed-refs | grep -v 'refs/pull' > packed-refs-new; echo 'Removed pull refs.'"
        - mv packed-refs-new packed-refs
        - bash -c "git push --force --mirror github 2>&1 | grep -v duniter-gitlab; echo $?"
```

# Adapt the readme file
Create an hidden file `.github/github_disclaimer.md` that indicates this is simply a clone of the main repo on gitlab with a link to the gitlab repository. Merge requests in gitlab should be used an not Pull requests in github.

Issues created in github will be manually duplicated in gitlab, and answer there, therefore users should open them directly on gitlab as soon as it is possible.

We should create a standard information message, explaining our choice.

Here is a proposal
```
# Initial disclaimer
This project is now tracked on our hosted gitlab server at:
https://git-sandbox.duniter.org/duniter/gitlab

The current github repository is a simple clone taken up to date at each push on the main gitlab repository.

All contributions should be performed on the main gitlab repository.

Pull requests proposed on github would generate more work for the main contributors.

Issues can be submitted on github. However, all issues created on github will be duplicated on gitlab manually and closed with a link to the gitlab issue.


# Original README.md
```

The `.gitlab-ci.yml` becomes
```
stages:
    - github-sync

push_to_github:
    stage: github-sync
    variables:
        GIT_STRATEGY: none
    script:
        - rm -rf ./*
        - rm -rf .git
        - git clone --mirror $CI_REPOSITORY_URL .
        - git remote add github $GITHUB_URL_AND_KEY
        - git config --global user.email "contact@duniter.org"
        - git config --global user.name "Duniter"
        # Job would fail if we don't remove refs about pull requests
        - bash -c "cat packed-refs | grep -v 'refs/pull' > packed-refs-new; echo 'Removed pull refs.'"
        - mv packed-refs-new packed-refs
        - bash -c "git push --force --mirror github 2>&1 | grep -v duniter-gitlab; echo $?"

enforce_readme:
    stage: github-sync
    variables:
        GIT_STRATEGY: none
    script:
      - rm -rf ./*
      - rm -rf .git
      - git clone $GITHUB_URL_AND_KEY .
      - git config --global user.email "contact@duniter.org"
      - git config --global user.name "Duniter"
      - git checkout master
      - cat .duniter/github_disclaimer.md > README.md.new
      - cat README.md >> README.md.new
      - cp README.md.new README.md
      - git commit -am "Enforce github readme"
      - git push origin master
```

# Create github templates
## Issue template
Create `.duniter/ISSUE_TEMPLATE.md`

```
Please note that all issues should be preferentially opened at
https://git-sandbox.duniter.org/duniter/gitlab/issues/new?issue

If you open issue here, it will be duplicated manually on our hosted gitlab and closed here with a link to our main repository.

Thank you for your understanding.
```

## Pull Requests template
Create `.duniter/PULL_REQUEST_TEMPLATE.md`

```
This project is now tracked on our hosted gitlab server at:
https://git-sandbox.duniter.org/duniter/gitlab

The current github repository is a simple clone taken up to date at each push on the main gitlab repository.

All contributions should be performed on the main gitlab repository.

Pull requests proposed on github would generate more work for the main contributors, therefore we would really appreciate if you can create instead merge requests on our hosted gitlab instance.

Thank you for your understanding.
```

## Contributing guide
Create `.duniter/CONTRIBUTING.md`

```
This project is now tracked on our hosted gitlab server at:
https://git-sandbox.duniter.org/duniter/gitlab

The current github repository is a simple clone taken up to date at each push on the main gitlab repository.

All contributions should be performed on the main gitlab repository.

Pull requests proposed on github would generate more work for the main contributors.

Issues can be submitted on github. However, all issues created on github will be duplicated on gitlab manually and closed with a link to the gitlab issue.
```
