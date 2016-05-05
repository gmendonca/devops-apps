# Méliuz DevOps

Dentro deste diretório você encontrará duas aplicações: uma escrita em python e outra em php.

As aplicações são muito simples, porém, elas devem ser implantadas em servidores diferentes conforme instruções do teste.

As aplicações possuem dependências, sendo elas:

PHP: Guzzle
Python: Flask

As dependências devem ser instaladas via composer (php) e pip (python).

Para a aplicação PHP funcionar, ela deverá ter acesso a uma variável de ambiente chamada `PYTHON_APP_ADDRESS`.
Essa variável deve conter o endereço web da aplicação Python, por exemplo: `http://python_app.meliuz.com.br`.

# Configurations

First you need to configure the environment in order to run the scripts. You can check how to install Amazon AWS CLI [here](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-set-up.html) and configure.

When configuring:

```bash
$ aws configure
AWS Access Key ID [None]: AKIAIOSFODNN7EXAMPLE
AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
Default region name [None]: sa-east-1
Default output format [None]: json
```
