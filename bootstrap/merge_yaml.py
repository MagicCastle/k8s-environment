import yaml

with open('data/k8s_base.yaml') as f:
    base = yaml.full_load(f)

with open('Centos.yaml') as f:
    certificates = yaml.full_load(f)

for k, v in certificates.items():
    if k not in base.keys():
        base[k] = v

with open('data/k8s.yaml', 'w') as f:
    yaml.dump(base, f)
