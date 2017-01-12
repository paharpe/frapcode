export AMIS_FTP_PATH="/home/ftpuser/PROD"


export AMIS_IMPORT_XML_FILE="AMISExport.xml"
export AMIS_IMPORT_IMAGES_DIR="Images"
export AMIS_IMPORT_PATH="/var/www/monumenten.acc.amsterdam.nl/open-file/AMIS"

export AMIS_IMPORT_LOG_PATH="/var/log/amis"
export AMIS_IMPORT_LOG_FNAME="xml_import_"
export AMIS_IMPORT_LOG_EXT=".log"
export AMIS_IMPORT_LOG_MAX_AGE=60

export AMIS_IMPORT_URL="https://monumenten.acc.amsterdam.nl/import.php?auto=true"
 
export AMIS_IMPORT_HTML_LOG_PATH="/root"
export AMIS_IMPORT_HTML_FILE="import.php*"

find ${AMIS_IMPORT_HTML_LOG_PATH} -name ${AMIS_IMPORT_HTML_FILE} -exec mv -t ${AMIS_IMPORT_LOG_PATH}/ {} \+
