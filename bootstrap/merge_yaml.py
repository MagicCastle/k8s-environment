import yaml
try:
    from yaml import full_load as load
except ImportError:
    # Support old version of pyYaml
    from yaml import load

with open('data/k8s_base.yaml') as f:
    base = load(f)

with open('Centos.yaml') as f:
    certificates = load(f)

for k, v in certificates.items():
    if k not in base.keys():
        base[k] = v

with open('data/k8s.yaml', 'w') as f:
    yaml.dump(base, f)
