# VueCertbot

VueCertbot is bunch of scripts, Docker and config files intended to be used to quickly setup a Vue webapp with a Let's Encrypt certificate and Nginx hosting.

VueCertbot allows creating a new Vue project, creating docker images to deploy the created vue project, and a free automatically renewing Let's Encrypt certificat through a
Certbot Docker image.

## Installation

Required Dependencies:
- [Docker](https://www.docker.com/)
- [Docker Compose](https://docs.docker.com/compose/install/)
- [OpenSSL](https://www.openssl.org/)
- [Vue](https://vuejs.org/)

## Usage

**Sidenote: For ARM you will need to edit the Dockerfile and docker-compose to use the ARM docker images**

1. Clone this repo
2. Open a terminal in the Git repo
3. Run `./buildtools.sh`
   1. Run `chmod +x ./buildtools.sh` beforehand if necessary

## License
[MIT](https://choosealicense.com/licenses/mit/)

```
Copyright 2021 Callum McLoughlin

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```