*** Settings ***
Documentation       Get the Certificate Level 2 of Robocorp

Library             RPA.Browser.Playwright
Library             RPA.Tables
Library             RPA.HTTP
Library             RPA.PDF
Library             RPA.FileSystem
Library             RPA.Archive
Library             RPA.Dialogs
Library             RPA.Robocorp.Vault


*** Variables ***
${RECEIPT_PATH}             ${OUTPUT_DIR}${/}receipt
${GLOBAL_RETRY_AMOUNT}      3x
${GLOBAL_RETRY_INTERVAL}    1s


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${orders}    Get Order information
    Open Challenge Website
    Create Directory    ${RECEIPT_PATH}
    FOR    ${order}    IN    @{orders}
        Fill in order information    ${order}
    END
    Create Zip File

    [Teardown]    Close browser and clean up file system


*** Keywords ***
Get csv url from user
    ${secret}    Get Secret    robotorder
    Add heading    Hi ${secret}[username], please provide URL
    Add text input    url
    ${result}    Run dialog
    Set Task Variable    ${CSV_URL}    ${result.url}

 Open Challenge Website
    ${robotConfig}    Get Secret    robotconfig
    New Context
    New Page    ${robotConfig}[weburl]

 Get Order information
    ${robotConfig}    Get Secret    robotconfig
    RPA.HTTP.Download    ${robotConfig}[csvurl]    ${CURDIR}${/}order.csv    overwrite=True
    ${orders}    Read table from CSV    ${CURDIR}${/}order.csv
    RETURN    ${orders}

Fill in order information
    [Arguments]    ${order}
    RPA.Browser.Playwright.Click    css=.modal-content .btn-warning
    Select Options By    css=select[id=head]    Value    ${order}[Head]
    Click    css=.stacked input[id=id-body-${order}[Body]]
    Fill Text    //label[contains(.,'3. Legs:')]/../input    ${order}[Legs]
    Fill Text    css=input[id=address]    ${order}[Address]
    Click    id=preview
    Wait Until Keyword Succeeds
    ...    ${GLOBAL_RETRY_AMOUNT}
    ...    ${GLOBAL_RETRY_INTERVAL}
    ...    Submit robot order
    ...    ${order}

Submit robot order
    [Arguments]    ${order}
    Click    id=order
    Take Screenshot    ${RECEIPT_PATH}${/}${order}[Order number]-robot.png    id=robot-preview-image
    Take Screenshot    ${RECEIPT_PATH}${/}${order}[Order number].png    id=receipt
    ${files}    Create List    ${RECEIPT_PATH}${/}${order}[Order number].png
    ...    ${RECEIPT_PATH}${/}${order}[Order number].png
    Add Files To Pdf    ${files}    ${RECEIPT_PATH}${/}${order}[Order number].pdf
    Remove File    ${RECEIPT_PATH}${/}${order}[Order number].png
    Remove File    ${RECEIPT_PATH}${/}${order}[Order number]-robot.png
    Click    id=order-another

Create Zip File
    Archive Folder With Zip    ${RECEIPT_PATH}    ${OUTPUT_DIR}${/}receipt.zip

Close browser and clean up file system
    RPA.Browser.Playwright.Close Browser
    ${hasDirectory}    Does Directory Exist    ${RECEIPT_PATH}
    IF    ${hasDirectory}    Remove Directory    ${RECEIPT_PATH}    True
    Close all dialogs
