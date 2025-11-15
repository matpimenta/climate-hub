# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an experimental TypeScript project that target resolving any problem by reasoning through the problems, plan steps and create specialised 
agents to handle complicated tasks. 

## Documentation

Only generate markdown files and documentation when asked. CLAUDE.md should always be updated when the project structure and new features and components are added. However, CLAUDE.md should be keep clean and concise.

## Terraform Validation

Whenever you make changes to the infrastructure folder, you should run `terraform plan` to verify the configuration.