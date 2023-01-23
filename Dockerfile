# Dockerfile Public A10G

# https://gitlab.com/nvidia/container-images/cuda/-/blob/master/dist/11.7.1/ubuntu2204/devel/cudnn8/Dockerfile
FROM nvidia/cuda:11.7.1-cudnn8-devel-ubuntu22.04
ENV DEBIAN_FRONTEND noninteractive

WORKDIR /content

RUN apt-get update -y && apt-get upgrade -y && apt-get install -y libgl1 libglib2.0-0 wget git git-lfs python3-pip python-is-python3 && pip3 install --upgrade pip
RUN pip install https://github.com/camenduru/stable-diffusion-webui-colab/releases/download/0.0.16/xformers-0.0.16+814314d.d20230119.A10G-cp310-cp310-linux_x86_64.whl
RUN pip install --pre triton
RUN pip install numexpr

RUN git clone -b v1.6 https://github.com/camenduru/stable-diffusion-webui
RUN sed -i -e '''/prepare_environment()/a\    os.system\(f\"""sed -i -e ''\"s/dict()))/dict())).cuda()/g\"'' /content/stable-diffusion-webui/repositories/stable-diffusion-stability-ai/ldm/util.py""")''' /content/stable-diffusion-webui/launch.py
RUN sed -i -e 's/    start()/    #start()/g' /content/stable-diffusion-webui/launch.py
RUN cd stable-diffusion-webui && python launch.py --skip-torch-cuda-test

ADD https://github.com/camenduru/webui-docker/raw/main/env_patch.py /content/env_patch.py
RUN sed -i -e '/import image_from_url_text/r /content/env_patch.py' /content/stable-diffusion-webui/modules/ui.py
ADD https://github.com/camenduru/webui-docker/raw/main/header_patch.py /content/header_patch.py
RUN sed -i -e '/demo:/r /content/header_patch.py' /content/stable-diffusion-webui/modules/ui.py

RUN sed -i -e '/(modelmerger_interface, \"Checkpoint Merger\", \"modelmerger\"),/d' /content/stable-diffusion-webui/modules/ui.py
RUN sed -i -e '/(train_interface, \"Train\", \"ti\"),/d' /content/stable-diffusion-webui/modules/ui.py
RUN sed -i -e '/extensions_interface, \"Extensions\", \"extensions\"/d' /content/stable-diffusion-webui/modules/ui.py
RUN sed -i -e '/settings_interface, \"Settings\", \"settings\"/d' /content/stable-diffusion-webui/modules/ui.py
RUN sed -i -e "s/document.getElementsByTagName('gradio-app')\[0\].shadowRoot/!!document.getElementsByTagName('gradio-app')[0].shadowRoot ? document.getElementsByTagName('gradio-app')[0].shadowRoot : document/g" /content/stable-diffusion-webui/script.js
RUN sed -i -e 's/                show_progress=False,/                show_progress=True,/g' /content/stable-diffusion-webui/modules/ui.py
RUN sed -i -e 's/default_enabled=False/default_enabled=True/g' /content/stable-diffusion-webui/webui.py
RUN sed -i -e 's/ outputs=\[/queue=False, &/g' /content/stable-diffusion-webui/modules/ui.py
RUN sed -i -e 's/               queue=False,  /                /g' /content/stable-diffusion-webui/modules/ui.py

RUN rm -rfv /content/stable-diffusion-webui/scripts/

ADD https://github.com/camenduru/webui-docker/raw/main/shared-config.json /content/shared-config.json
ADD https://github.com/camenduru/webui-docker/raw/main/shared-ui-config.json /content/shared-ui-config.json

ADD https://huggingface.co/ckpt/grapefruit/resolve/main/grapefruit.safetensors /content/stable-diffusion-webui/models/Stable-diffusion/grapefruit.safetensors
ADD https://huggingface.co/ckpt/grapefruit/resolve/main/grapefruit.vae.pt /content/stable-diffusion-webui/models/Stable-diffusion/grapefruit.vae.pt

RUN adduser --disabled-password --gecos '' user
RUN chown -R user:user /content
RUN chmod -R 777 /content
USER user

EXPOSE 7860

CMD cd /content/stable-diffusion-webui && python webui.py --xformers --listen --disable-console-progressbars --enable-console-prompts --no-progressbar-hiding --ui-config-file /content/shared-ui-config.json --ui-settings-file /content/shared-config.json