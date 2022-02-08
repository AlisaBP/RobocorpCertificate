*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.FileSystem
Library           RPA.Archive
Library           RPA.Dialogs
Library           RPA.Robocorp.Vault

*** Keywords ***
Ask for website link
    Add heading       Provide link to website
    Add text input    link
    ...    label=Link to website
    ...    placeholder=Enter link to website here
    ...    rows=1
    ${result}=    Run dialog
    [Return]   ${result.link}


*** Keywords ***
Open the robot order website
    [Arguments]    ${link}
    #Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    Open Available Browser    ${link}
    Create Directory    ${OUTPUT_DIR}${/}temp

*** Keywords ***
Consent
    Click Button    css:.btn-dark

*** Keywords ***
Get orders
    [Arguments]    ${linkToFile}
   # Download    https://robotsparebinindustries.com/orders.csv   overwrite=True
    Download    ${linkToFile}   overwrite=True
    ${table}=    Read table from CSV    orders.csv
    [Return]    ${table}

*** Keywords ***
Fill the form
    [Arguments]    ${row}
    Select From List By Value    id:head  ${row}[Head]
    Click Element    id:id-body-${row}[Body]
    Input Text    xpath://label[contains(.,'3. Legs:')]/../input  ${row}[Legs]
    Input Text   id:address  ${row}[Address]


*** Keywords ***
Preview the robot
    Click Button    id:preview

*** Keywords ***
Submit the order
    Wait Until Keyword Succeeds    5x    2s     Click Order


*** Keywords ***
Click Order
    Click Button    id:order
    Wait Until Page Contains Element    id:receipt

*** Keywords ***
Go to order another robot
    Click Button    id:order-another

*** Keywords ***
Store the receipt as a PDF file
    [Arguments]    ${number}
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${OUTPUT_DIR}${/}temp${/}receipt-${number}.pdf
    [Return]    ${OUTPUT_DIR}${/}temp${/}receipt-${number}.pdf

*** Keywords ***
Take a screenshot of the robot
    [Arguments]     ${number}
    Screenshot    id:robot-preview-image   ${OUTPUT_DIR}${/}screenshot-${number}.png
    [Return]    ${OUTPUT_DIR}${/}screenshot-${number}.png

*** Keywords ***
Embed the robot screenshot to the receipt PDF file
    [Arguments]     ${screenshot}  ${pdf}
    Open PDF    ${pdf}
    ${files}=    Create List
    ...    ${screenshot}
    ...    ${pdf}
    Add Files To PDF    ${files}    ${pdf}
    Close Pdf  ${pdf}

*** Keywords ***
Create a ZIP file of the receipts
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}${/}PDFs.zip
    Archive Folder With Zip
    ...    ${OUTPUT_DIR}${/}temp
    ...    ${zip_file_name}

*** Keywords ***
Close Robocorp Browser
        Close Browser

*** Keywords ***
Get secret data
     ${secret}=  Get Secret    OrderCSV
     [Return]    ${secret}

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${secret}=  Get secret data
    Log    ${secret}[linkToCSV]
    ${website link}=  Ask for website link
    Open the robot order website    ${website link}
    ${orders}=    Get orders   ${secret}[linkToCSV]
     FOR    ${row}    IN    @{orders}
        Consent
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=     Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file   ${screenshot}    ${pdf}
        Go to order another robot
     END
    Create a ZIP file of the receipts
    [Teardown]  Close Robocorp Browser

