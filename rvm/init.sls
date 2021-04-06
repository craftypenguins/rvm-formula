{% from "rvm/map.jinja" import rvm with context %}

rvm_deps:
  pkg.installed:
    - refresh: True
    - pkgs:
      {{ rvm.pkgs | yaml(False) | indent(6) }}

rvm_user:
  group.present:
    - name: rvm
    - gid: 2000

rvm-install-gpgkey:
  cmd:
    - run
    - user: root
    - name: gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
    - unless: gpg --list-keys | grep D39DC0E3

rvm_install:
  cmd:
    - run
    - user: root
    - name: curl -sSL https://get.rvm.io | bash -s stable --quiet-curl --rails
    - onlyif: test ! -f /usr/local/rvm/bin/rvm

rvm_requirements:
  cmd.run:
    - name: /usr/local/rvm/bin/rvm requirements

# install rubies with Salt state rvm.installed

{% for ruby_version, ruby_row in salt['pillar.get']('rvm:rubies:', { } ).items() %}

ruby-{{ ruby_version }}:
  rvm.installed:
    - user: {{ ruby_row.user }}
    {% if ruby_version.default is defined and rvm.default == ruby_version %}
    - default: True
    {% endif %}
    - require:
      - cmd: rvm

# install gems
{% if 'gems' in ruby_row %}
{% for gems in ruby_row.gems.items() %}

{% set gem_r = gem.split("-") %}
{% set gem_version = "" %}
{% if gem_r[1] is defined %}
  {% set gem_version = "-v " + gem_r[1] %}
{% endif %}

rvm-install-gems-{{ruby_version}}-{{gem}}:
  cmd:
    - run
    - user: root
    - name: "bash -l -c 'rvm use {{ruby_version}}  &&  gem install {{gem_r[0]}} {{gem_version}}'"
    - unless: "bash -l -c 'rvm use {{ruby_version}}  &&  gem list | grep {{gem_r[0]}}'"

# for gems 
{% endfor %}

# if gems
{% endif %}

# for ruby_version, ruby_row
{% endfor %}

