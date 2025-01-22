# ASMB Research Paper Explorer

The **ASMB Research Paper Explorer** is a Shiny application designed to make exploring research papers from the ASMB collection more interactive and user-friendly. You can access the app at the following URL:

[ASMB Research Paper Explorer](https://michaelwillox.github.io/ASMBResearchPaperExplorer/)

The Analytical Studies and Modelling Branch (ASMB) is the research arm of Statistics Canada mandated to provide high-quality, relevant and timely information on economic, health and social issues that are important to Canadians. The branch strategically makes use of expert knowledge and a broad range of data sources and modelling techniques to address the information needs of a broad range of government, academic and public sector partners and stakeholders through analysis and research, modeling and predictive analytics, and data development. The branch strives to deliver relevant, high-quality, timely, comprehensive, horizontal and integrated research and to enable the use of its research through capacity building and strategic dissemination to meet the user needs of policy makers, academics and the general public.

## Features

This app allows users to:

- **Filter Research Papers:**
  - By Journals and Periodicals
  - By Issue Number
  - By Author
  - By Keyword
  - By Release Date
  - By Title
  - By Release Type

- **Customize Displayed Columns:**
  - Use the checkbox group to select which variables to display in the results table.

- **Search and Explore:**
  - View an interactive table of filtered research papers.
  - Use expandable rows to see more information about each paper.

- **Download Results:**
  - Download the filtered results table as a CSV file for offline use.

## How to Use

1. Navigate to the app: [ASMB Research Paper Explorer](https://michaelwillox.github.io/ASMBResearchPaperExplorer/).
2. Use the dropdown menus in the sidebar to filter the research papers by various attributes.
3. Customize the variables displayed in the results table by selecting or deselecting columns.
4. View the filtered results in an interactive table displayed in the main panel.
5. If needed, download the filtered table as a CSV file by clicking the "Download Table" button.

## About the Data

The app uses a nested dataset of ASMB research papers, which has been pre-processed and flattened for ease of filtering and display. Users can interact with various metadata fields such as:

- **Articles/Reports:** The source of the paper (e.g., journal or report name).
- **Issue Number:** The specific issue in which the paper appears.
- **Authors:** The authors of the paper.
- **Keywords:** Key terms associated with the paper.
- **Release Date:** The publication date of the paper.
- **Title:** The title of the paper.
- **Release Type:** The type of release (e.g., journal article, report).

## Downloading Data

To download the filtered data:

1. Apply your desired filters using the dropdown menus.
2. Click the "Download Table" button.
3. Save the CSV file to your local machine.

The downloaded file will include only the data that matches your selected filters.
