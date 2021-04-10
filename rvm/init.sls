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

rvm_install_gpgkey:
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

{# {% for ruby_version, ruby_row in rvm.rubies|dictsort %} #}
{% for ruby_version, ruby_row in salt['pillar.get']('rvm:rubies', {}).items() %}

{# Not working--errors with duplicate saltID's when the same user is declared for multiple rubyversions

{% if ruby_row.user is defined %}
{% set ruby_user_home = salt['user.info'](ruby_row.user).home %}
rvm_{{ ruby_row.user }}_bashrc:
  cmd:
    - run
    - name: echo "[[ -s {{ ruby_user_home }}/.rvm/scripts/rvm ]] && source {{ ruby_user_home }}/.rvm/scripts/rvm" >> {{ ruby_user_home }}/.bashrc
    - user: {{ ruby_user_home }}
    - unless: grep ".rvm/scripts/rvm" {{ ruby_user_home }}/.bashrc
{% endif %}
#}

ruby-{{ ruby_version }}:
  rvm.installed:
    - name: ruby-{{ ruby_version }}
    - user: {{ ruby_row.user }}
    {% if rvm.default is defined and rvm.default == ruby_version %}
    - default: True
    {% endif %}
    - require:
      - rvm_install

# install gems
{% if 'gems' in ruby_row %}
{% for gem in ruby_row.gems|list %}

{% set gem_r = gem.split("-") %}
{% set gem_version = "" %}
{% if gem_r[1] is defined %}
  {% set gem_version = "-v " + gem_r[1] %}
{% endif %}

rvm_install_gems_{{ruby_version}}-{{gem}}:
  cmd:
    - run
    - user: root
    - name: "bash -l -c 'rvm use {{ruby_version}}  &&  gem install {{gem_r[0]}} {{gem_version}}'"
    - unless: "bash -l -c 'rvm use {{ruby_version}}  &&  gem list | grep {{gem_r[0]}}'"
    - require:
      - rvm_install

# for gem 
{% endfor %}

# if gems
{% endif %}

# for ruby_version, ruby_row
{% endfor %}

