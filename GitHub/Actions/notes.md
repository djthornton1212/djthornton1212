# GitHub Actions Quick Notes

## Commands

### URL Encoded

Note that your whole command must be on a single line, and characters that interfere with the parsing (comma, newline, etc.) need to be URL encoded. You can use the following table to implement replacement rules for the characters.

| Character | Encoded value |	Scope
|---|---|---|
| `%` | `%25` | parameter, value|
| `\r` | `%0D` |parameter, value|
| `\n` | `%0A` | parameter, value|
| `:` | `%3A` | parameter|
| `,` | `%2C` | parameter|

Soure: [Do More with Workflow Commands for GitHub Actions](https://pakstech.com/blog/github-actions-workflow-commands/) JANNE KEMPPAINEN  

### Environment Variables

Print secrets for recovery purposes:

```bash
echo "$OUTPUT" | sed 's/./& /g'
```

#### Python

You cannot set environment variables directly. Instead, you need to write your environment variables into a file, whose name you can get via $GITHUB_ENV.

In a simple workflow step, you can append it to the file like so (from the docs):

```shell
echo "{name}={value}" >> $GITHUB_ENV
In python, you can do it like so:
```

```python
import os

env_file = os.getenv('GITHUB_ENV')

with open(env_file, "a") as myfile:
    myfile.write("MY_VAR=MY_VALUE")
Given this python script, you can set and use your new environment variable like the following:
```

```actions
- run: python write-env.py
- run: echo ${{ env.MY_VAR }}
```

Source: [How to set environment variables in GitHub actions using python](https://stackoverflow.com/questions/70123328/how-to-set-environment-variables-in-github-actions-using-python) rethab


"I asked me how to set two or more environment variables. You have te seperate these variables with a linebreak. Here is an example:"

```python
import os

env_file = os.getenv('GITHUB_ENV')

with open(env_file, "a") as myfile:
    myfile.write("MY_VAR1=MY_VALUE1\n")
    myfile.write("MY_VAR2=MY_VALUE2")
```

Source: [How to set environment variables in GitHub actions using python](https://stackoverflow.com/questions/70123328/how-to-set-environment-variables-in-github-actions-using-python) Georg Bauer
