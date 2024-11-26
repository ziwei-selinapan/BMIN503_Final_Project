---
editor_options: 
  markdown: 
    wrap: 72
---

# BMIN503/EPID600 Final Project

This project investigates the impact of different valve prosthesis
procedures on mortality rates among patients with end-stage renal
disease (ESRD), while accounting for the competing risk of kidney
transplantation. The primary goal is to identify the most suitable valve
procedure for ESRD patients based on survival outcomes and other
secondary outcomes, including various types of readmissions.

## Methodology

#### Data Preparation

I created the analytical dataset by cleaning and filtering data from the
Medicare and Carrier Claim datasets, focusing on patients who underwent
one of the following procedures:

-   Open-chest aortic or mitral valve replacement (AVR/MVR)

-   Minimally invasive transcatheter aortic valve replacement (TAVR)

#### Propensity Score Matching

The key characteristics of patients in the three procedure groups
(mechanical AVR vs. bioprothetic AVR vs. TAVR) were slightly different,
including factors such as age, sex, Elixhauser comorbidity score, and
history of ESRD. To address these differences, I performed two sets of
pairwise propensity score matching to create two evenly matched
analytical cohorts. This matching process helps to reduce bias and
improve the comparability of the two valve procedures, allowing for a
more accurate comparison of outcomes.

#### Statistical Modeling

After consulting with Professor Jesse Yenchih Hsu, cardiologist Dr.
Chase Brown, and Waseem Lutfi, I used logistic regression and competing
risk modeling to identify the most suitable valve procedure for ESRD
patients. The Fine and Gray competing risk model was employed to account
for the fact that multiple types of events (e.g., mortality vs. kidney
transplantation) can occur, with the occurrence of one event potentially
precluding the occurrence of another.

The models assessed both survival outcomes and seven secondary outcomes,
including common reasons for hospital readmission, such as congestive
heart failure (CHF), hemorrhage, and stroke.

## Project Updates (November 26)

I have uploaded the first draft of my work to this repository. The draft
includes:

-   Descriptive statistics and visualizations (graphs)

-   Results from the propensity score matching process

-   Preliminary results from one set of competing risk modeling (with
    primary outcome)

-   Supplemental material : codes on data cleaning

#### Data Cleaning and Code Limitations

Due to data security restrictions, I was unable to include the full code
for data cleaning, as it was performed on a secure server (UPENN PMACS
HSRDC). However, I will summarize the data cleaning steps and provide
comments within the code to help others understand my process in the
following week.

#### Work Left for Final Version

**Competing Risk Modeling:**\
Due to time constraints and limited experience with R, I have only
completed one set of competing risk modeling. Initially, I performed
some of the analysis in STATA (which I'm more familiar with), so some of
the results presented in this draft were generated using STATA models.

**Replication of Results:**\
In the next update, I plan to replicate my results from STATA to R,
generate cumulative incidence plots, and provide a more comprehensive
methods section with detailed comments to help explain my approach.

Thank you for taking the time to review my work! If you have any
questions or feedback, please feel free to reach out.
