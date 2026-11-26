FROM librenms/librenms:latest

# Corrige a incompatibilidade do setuptools 82+ com dynamic_check_requirements.py (pkg_resources)
# e garante compatibilidade estavel com todas as rotinas Python do LibreNMS
RUN pip3 install --no-cache-dir --break-system-packages "setuptools<80"
