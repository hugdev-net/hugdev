curl -fsSL https://pyenv.run | bash

echo '
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - bash)"
' >> ~/.bash_profile

source ~/.bash_profile


sudo apt update
sudo apt install -y libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev  \
    libncurses5-dev libncursesw5-dev tk-dev libffi-dev liblzma-dev git


PYTHON_VERSION=3.10.13
pyenv install $PYTHON_VERSION
pyenv global $PYTHON_VERSION
pyenv virtualenv $PYTHON_VERSION python_env
pyenv activate python_env


pip install poetry==2.1.3 -i https://mirrors.aliyun.com/pypi/simple/ --retries 10 --timeout 60
pip install poetry-plugin-export==1.9.0 -i https://mirrors.aliyun.com/pypi/simple/ --retries 10 --timeout 60
pip install gunicorn==23.0.0 -i https://mirrors.aliyun.com/pypi/simple/ --retries 10 --timeout 60
