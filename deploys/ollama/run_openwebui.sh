#https://docs.openwebui.com/getting-started/quick-start

docker run -d -p 3000:8080 --gpus all -e OLLAMA_HOST=http://host.docker.internal:11434 -v open-webui:/app/backend/data --name open-webui --restart always ghcr.io/open-webui/open-webui:cuda