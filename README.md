<p align="center">
    <img width="240" style="border: 3px solid #fff;" src="media/git-get-cloned.png" alt="Git Get Cloned Logo">
<p>
<h1 align="center">Git Get Cloned Action</h1>

> Github Action for copying files to other repositories, in an easy and repeatable way.

## Inspiration 
 - [copycat-action](https://github.com/andstor/copycat-action)

## Support services
 - GitHub

## Usage

The following workflow example will use as many default options as possible. It will clone the current repository running the github action into a new repository using a simple workflow.

```yaml
    - name: Clone
      uses: Bits-To-Breath/git-get-cloned-action@v1
      with:
        source_auth_id: Bits-To-Breath
        source_auth_token: ${{ secrets.PERSONAL_TOKEN }}
        destination_owner: Bits-To-Breath
        destination_repo_name: example-temp
```

## Features
 - Clone a repository; create new source and destination repository if they do not yet exist
 - Clone with two [perl regexes](https://regex101.com/) for filtering specific files and folders to select and then ignore
 - Clone specific repository source to specific repository destination (unrelated to repository workflow is running from)
 - Clone paths for specific parts of the repository to be cloned to specific destinations
 - Clone optionally with separate credentials for source and destination repositories
 - Clone wiki additionally if needed
 - Clone specific branch at source and to specific destination branch, with specific default branch at source and destination; creates new branches, derived from the default branch if possible
 - Clone using specific commit message, email and username (username should pair with the access token)

## Options ⚙️

The following is the exhaustive list of options:

<div id="options"></div>

|Input variable|Necessity|Description|Default|
|-----|-----|-------------------|-----|
|`source_auth_id`|Required|The authentication id of the source repository. For example `oauth2` or [`Bits-To-Breath`](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token).||
|`source_auth_token`|Required|The authentication token of the source repository.||
|`destination_owner`|Required|The owner of the destination repository; organization or user.||
|`destination_repo_name`|Required|The destination repository name.||
|`select_regex`|Optional|The select regex chooses files or folders, using [regexe(s)](https://regex101.com/), to collect.|`(.*)`|
|`ignore_regex`|Optional|The ignore regex chooses files or folders, using [regexe(s)](https://regex101.com/), to collect.|`(.*\/\.git\/.*)`|
|`commit_message`|Optional|The message to show during automated commits.|(brief summary string with timestamp)|
|`commit_username`|Optional|The message to show during automated commits.|[${GITHUB_ACTOR}](https://docs.github.com/en/actions/learn-github-actions/environment-variables#default-environment-variables)|
|`commit_email`|Optional|The message to show during automated commits.|`${COMMIT_USERNAME}@users.noreply.github.com`|
|`source_is_private`|Optional|The source repository is private.|`true`|
|`source_is_template`|Optional|The source repository is template.|`false`|
|`source_service`|Optional|The source repository service.|`github.com`|
|`source_owner`|Optional|The owner of the source repository; organization or user.|[$GITHUB_REPOSITORY_OWNER](https://docs.github.com/en/actions/learn-github-actions/environment-variables#default-environment-variables)|
|`source_repo_name`|Optional|The source repository name.|[${GITHUB_REPOSITORY#*/}](https://docs.github.com/en/actions/learn-github-actions/environment-variables#default-environment-variables)|
|`source_branch`|Optional|The source branch to collect files from.|`main`|
|`source_default_branch`|Optional|The source default branch to collect files from.|`main`|
|`source_path`|Optional|The source path in the repository to collect files from.||
|`source_wiki`|Optional|The source wiki path.||
|`destination_is_private`|Optional|The destination repository is private.|`true`|
|`destination_is_template`|Optional|The destination repository is template.|`false`|
|`destination_service`|Optional|The destination repository service.|`github.com`|
|`destination_path`|Optional|The path to put the source files.||
|`destination_branch`|Optional|The destination branch to collect files from.|`main`|
|`destination_default_branch`|Optional|The destination default branch to collect files from.|`main`|
|`destination_path`|Optional|The destination path in the repository to collect files from.||
|`destination_wiki`|Optional|The destination wiki path.||
|`code_env`|Optional|The code environment; may become an relevant feature in future. `pre-dev` is used for locally development.||

# Contributing

Steps for testing locally

 1. Clone this repository.
 2. create `.env` from `.example.env`
 3. populate `.env` with your information
 4. begin editing entrypoint.sh
 5. type `bash` or `zsh` to start another terminal inside your current terminal
 6. type `. ./load_env.sh` to load all the required variables
 7. type `. ./entrypoint.sh` to run the code
 8. begin making your changes to fix bugs or add features

## Author

The Git Get Cloned Action is written by [Austin Hogan](https://bitstobreath.com) [ausgan.93+bitstobreath.com@gmail.com](mailto:ausgan.93+bitstobreath.com@gmail.com)

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT) - see the [LICENSE](LICENSE) file for details.
