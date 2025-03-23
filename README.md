# 🚀 deploy.bolt

Custom LLM deployment system for bolt.diy - spin up your own AI models with minimal hassle.

## 🔥 Features

- One-shot model setup and deployment
- Custom provider creation
- Automatic API endpoint generation
- Real-time monitoring
- Config file archiving
- ngrok tunnel support

## 📁 Structure


deploy.bolt/
├── ascii/ # ASCII art for that clean CLI look
├── custom/ # Custom model setup scripts
│ ├── create_custom.sh
│ ├── input_info.sh
│ ├── templates/
│ ├── tokens/
│ └── verify_custom.sh
├── scratch/ # Fresh install scripts
│ ├── dependencies.sh
│ └── install_bolt.sh
└── spin/ # Model deployment scripts
├── expose.bolt.sh
├── get.model.py
├── monitor.sh
└── spin.bolt.sh


## 🚦 Quick Start

1. Clone this repo:
```bash
git clone https://github.com/m5trevino/deploy.bolt.git
cd deploy.bolt

    Run the launcher:

bash

Copy Code
python3 run.py

    Choose your path:

    Fresh Install: Full setup from scratch
    Add New LLM: Add model to existing setup
    Use Existing: Launch saved model

💾 Model Storage

Models are stored in /root/llm/models/[model_name]
Config files are archived in /home/flintx/deploy.bolt/archive/[model_name]
🔧 Configuration

Custom model configs are automatically:

    Created in bolt.diy directory
    Archived for future use
    Verified before deployment

🎯 Supported Models

    Any GGUF format model
    Tested with:
        CodeLlama
        DeepSeek
        Mistral
        (Any other GGUF compatible model)

📊 Monitoring

Real-time monitoring of:

    Model server status
    bolt.diy server
    ngrok tunnel
    System resources
    Port status

🛠️ Requirements

    Python 3.8+
    bolt.diy
    ngrok (optional, for tunneling)
    System requirements depend on model size

🤝 Contributing

Pull requests welcome! Check issues for needed features.
📜 License

MIT License - Do your thing, just keep it 💯
🙏 Credits

Built for the streets, powered by:

    bolt.diy
    llama.cpp
    huggingface
    Your favorite GGUF models

Built with 🔥 by @m5trevino
