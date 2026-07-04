FROM mcr.microsoft.com/azure-functions/python:4-python3.11

ENV AzureWebJobsScriptRoot=/home/site/wwwroot \
    AzureFunctionsJobHost__Logging__Console__IsEnabled=true

# Install to .python_packages/lib/site-packages/ – the path the Azure Functions
# bundled Python worker adds to sys.path at runtime.
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt \
    --target /home/site/wwwroot/.python_packages/lib/site-packages

# Copy function app code
COPY . /home/site/wwwroot
