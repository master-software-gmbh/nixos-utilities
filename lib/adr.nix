{ ... }: pkgs: let
  init = pkgs.writeShellScriptBin "adr-init" ''
    mkdir -p ./docs/adrs
    echo "# 1. Record architecture decisions

Date: $(date '+%Y-%m-%d')

## Status

Accepted

## Context

I need to record the architectural decisions made on this project.

## Decision

I will use Architecture Decision Records, as described by Michael Nygard in this article: http://thinkrelevance.com/blog/2011/11/15/documenting-architecture-decisions

## Consequences

See Michael Nygard's article, linked above." > ./docs/adrs/0001-record-architecture-decisions.md
  '';
  new = pkgs.writeShellScriptBin "adr-new" ''
    mkdir -p ./docs/adrs
    echo "# 

Date: $(date '+%Y-%m-%d')

## Status

Accepted

## Context



## Decision



## Consequences

" > ./docs/adrs/new.md
  '';
in [
  init
  new
]