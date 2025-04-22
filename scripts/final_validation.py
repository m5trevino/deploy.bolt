#!/usr/bin/env python3
from pathlib import Path
from rich.console import Console
import shutil
import os

console = Console()

def validate_and_setup():
  """Validate and set up all config files for bolt.diy"""
  try:
     bolt_dir = Path("/home/flintx/deploy.bolt") # Updated path
     if not bolt_dir.exists():
         console.print("[red]Error: deploy.bolt directory not found![/red]")
         return False

     # Create provider file
     console.print("\n[cyan]Creating Mixtral provider...[/cyan]")
     provider_dir = bolt_dir / "app" / "lib" / "modules" / "llm" / "providers"
     provider_dir.mkdir(parents=True, exist_ok=True)

    with open(provider_dir / "mixtral-local.ts", "w") as f:
        f.write("""import { BaseProvider } from '~/lib/modules/llm/base-provider';
import type { ModelInfo } from '~/lib/modules/llm/types';
import type { IProviderSetting } from '~/types/model';
import type { LanguageModelV1 } from 'ai';
import { createOpenAI } from '@ai-sdk/openai';

export default class MixtralLocalProvider extends BaseProvider {
 name = 'MixtralLocal';
 getApiKeyLink = '';

 config = {
   apiTokenKey: '',
 };

 staticModels: ModelInfo[] = [
␌      {
          name: 'mixtral-8x7b-local',
          label: 'Mixtral-8x7B-Local',
          provider: 'MixtralLocal',
          maxTokenAllowed: 8192,
      }
 ];

 getModelInstance(options: {
   model: string;
   serverEnv: Env;
   apiKeys?: Record;
   providerSettings?: Record;
 }): LanguageModelV1 {
   const openai = createOpenAI({
     baseURL: 'http://localhost:8080/v1',
     apiKey: 'not-needed',
   });

    return openai(options.model);
  }
}""")
       console.print("[green] Provider file created[/green]")

           # Update registry
           console.print("\n[yellow]Updating registry...[/yellow]")
           registry_path = bolt_dir / "app" / "lib" / "modules" / "llm" / "registry.ts"
           if not registry_path.exists():
               console.print("[red]Error: registry.ts not found![/red]")
               return False

           with open(registry_path, "r") as f:
              content = f.read()

           # Add MixtralLocalProvider import and export
           if "MixtralLocalProvider" not in content:
               # Add import
               content = content.replace(
                  "import GithubProvider from './providers/github';",
                  "import GithubProvider from './providers/github';\nimport MixtralLocalProvider from './providers/mixtral-local';"
               )
               # Add export
               content = content.replace(
                  " GithubProvider,",
                  " GithubProvider,\n MixtralLocalProvider,"
               )
               with open(registry_path, "w") as f:
                  f.write(content)
           console.print("[green] Registry updated[/green]")

           # Set up vite config
           console.print("\n[yellow]Setting up vite.config.ts...[/yellow]")
           source_vite = Path("/home/flintx/deploy.bolt/vite.config.ts")
           dest_vite = bolt_dir / "vite.config.ts"
           if source_vite.exists():
               shutil.copy(source_vite, dest_vite)
               console.print("[green] Vite config created[/green]")
           else:
               console.print("[red]Error: source vite.config.ts not found![/red]")
               return False

           # Set up env file
           console.print("\n[yellow]Setting up .env.local...[/yellow]")
           source_env = Path("/home/flintx/deploy.bolt/.env.example")
           dest_env = bolt_dir / ".env.local"
           if source_env.exists():
               shutil.copy(source_env, dest_env)
               console.print("[green] Environment file created[/green]")
           else:
               console.print("[red]Error: source .env.local not found![/red]")
               return False

           console.print("\n[green] All configuration files validated and set up successfully![/green]")
           return True
␌  except Exception as e:
    console.print(f"[red]Error during validation: {str(e)}[/red]")
    return False

if __name__ == "__main__":
    validate_and_setup()
