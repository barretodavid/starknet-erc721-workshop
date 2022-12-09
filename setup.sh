#!/bin/sh
rm -rf env
python3.9 -m venv env
source env/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
deactivate