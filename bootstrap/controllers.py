#!/bin/python

from yaml import load

with open('data/terraform_data.yaml') as file:
    data = load(file)
    controllers = []
    for key, values in data['terraform']['instances'].items():
        if 'controller' in values['tags']:
            controllers.append("{}:{}".format(key, values['local_ip']))

print(",".join(controllers))