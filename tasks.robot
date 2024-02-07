*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library           RPA.Browser.Selenium
Library    RPA.HTTP
Library    RPA.Tables
Library    RPA.PDF
Library    RPA.Archive

*** Variables ***
${URL}               https://robotsparebinindustries.com/#/robot-order
${URL_ORDERS}        https://robotsparebinindustries.com/orders.csv
${DEFAULT_TIMEOUT}   30

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${ORDERS}                          Get Orders
    FOR            ${ORDER}            IN   @{ORDERS} 
        Close the annoying modal
        Fill the form                  ${ORDER}
        Preview the robot
        Submit the order   
        ${PDF}  Store the receipt as a PDF file  ${ORDER}[Order number]
        ${SCREENSHOT}  Take a screenshot of the robot   ${ORDER}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${SCREENSHOT}    ${PDF}
        Back to the form
    END
    Create a ZIP file
*** Keywords ***
Open the robot order website
    Open Browser                       ${URL}                  headlesschrome      #  Chrome    #                      
Get Orders
    Download                           ${URL_ORDERS}                 ${OUTPUT_DIR}/orders.csv                overwrite=${True}
    ${TABLE}                           Read table from CSV           ${OUTPUT_DIR}/orders.csv
    RETURN                             ${TABLE}
Close the annoying modal
    Click Element                      css=button[class="btn btn-dark"]
Fill the form
    [Arguments]                        ${ORDER}
    Select From List By Value          css=#head                     ${ORDER}[Head]
    Click Element                      css=#id-body-${ORDER}[Body]
    Input Text                         css=input[placeholder="Enter the part number for the legs"]           ${ORDER}[Legs]
    Input Text                         css=#address                  ${ORDER}[Address]
Preview the robot
    Wait Until Element Is Visible      css=button[id="preview"]      ${DEFAULT_TIMEOUT}
    Scroll Element Into View           css=button[id="preview"]
    Click Element                      css=button[id="preview"]
    Wait Until Element Is Visible      css=div[id="robot-preview"]   ${DEFAULT_TIMEOUT}
Submit the order
    Wait Until Element Is Visible      css=button[class="btn btn-primary"]                         ${DEFAULT_TIMEOUT}
    Scroll Element Into View           css=button[class="btn btn-primary"]
    Click Element                      css=button[class="btn btn-primary"]
    ${ERROR_MESSAGE}                   Run Keyword And Return Status  Wait Until Element Is Visible  css=p[class="badge badge-success"]  1
    WHILE   ${ERROR_MESSAGE} == False  limit=5
        Wait Until Element Is Visible  css=button[class="btn btn-primary"]                         ${DEFAULT_TIMEOUT}
        Scroll Element Into View       css=button[class="btn btn-primary"]
        Click Element                  css=button[class="btn btn-primary"]
        ${ERROR_MESSAGE}               Run Keyword And Return Status  Wait Until Element Is Visible  css=p[class="badge badge-success"]  1
    END
Back to the form
    Wait Until Element Is Visible      css=button[id="order-another"]                              ${DEFAULT_TIMEOUT}
    Scroll Element Into View           css=button[id="order-another"]     
    Click Element                      css=button[id="order-another"]
    Wait Until Element Is Visible      css=#head                                                   ${DEFAULT_TIMEOUT}
Store the receipt as a PDF file
    [Arguments]                        ${ORDER_NUMBER}
    ${Text}  Get Text                  css=#receipt
    Html To Pdf                        ${Text}        ${OUTPUT_DIR}\\receipts\\${ORDER_NUMBER}.pdf
    RETURN                             ${OUTPUT_DIR}\\receipts\\${ORDER_NUMBER}.pdf
Take a screenshot of the robot
    [Arguments]                        ${ORDER_NUMBER}
    Screenshot                         css=div[id="robot-preview"]   ${OUTPUT_DIR}\\receipts\\${ORDER_NUMBER}.png
    RETURN                             ${OUTPUT_DIR}\\receipts\\${ORDER_NUMBER}.png
Embed the robot screenshot to the receipt PDF file    
    [Arguments]                        ${SCREENSHOT}                 ${PDF}
    @{FILES}                           Create List                   ${SCREENSHOT}    
    Add Files To Pdf                   ${FILES}                      ${PDF}        True        
Create a ZIP file
    Archive Folder With Zip            ${OUTPUT_DIR}\\receipts    ${OUTPUT_DIR}\\receipts.zip    include=*.pdf