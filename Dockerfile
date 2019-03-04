FROM python:3.6-alpine as base

FROM base as builder
RUN pip install --target=/install --trusted-host pypi.python.org Flask

FROM base
COPY --from=builder /install /usr/local/lib/python3.6/site-packages
WORKDIR /app
ADD /app/. /app
ENV NAME World
CMD ["python", "app.py"]
