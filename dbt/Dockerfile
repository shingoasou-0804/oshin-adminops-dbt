ARG PYTHON_VERSION
FROM python:3.12-slim

WORKDIR /app

RUN apt-get update -qq \
    && apt-get install --no-install-recommends -yq \
    build-essential \
    curl \
    git \
    less \
    && apt-get clean \
    && rm -rf /var/cache/apt/archives/* \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && truncate -s 0 /var/log/*log

ENV TZ=Asia/Tokyo

COPY ./bin/install_poetry.sh .poetry-version ./
RUN chmod +x ./install_poetry.sh && ./install_poetry.sh

COPY pyproject.toml poetry.lock* ./
RUN poetry config virtualenvs.create false \
    && poetry install --no-interaction --no-ansi --with dev,dbt
