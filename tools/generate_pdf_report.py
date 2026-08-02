#!/usr/bin/env python3
"""
PDF Report Generator for 5-Stage RISC-V Core Project
Converts project_report.md into a beautifully formatted RISC-V_Core_Design_Final_Report.pdf
using ReportLab.
"""

import sys
import os
import re

from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak, KeepTogether, HRFlowable
)
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_JUSTIFY, TA_RIGHT
from reportlab.pdfgen import canvas


class NumberedCanvas(canvas.Canvas):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_header_footer(num_pages)
            super().showPage()
        super().save()

    def draw_header_footer(self, page_count):
        self.saveState()
        self.setFont("Helvetica", 9)
        self.setFillColor(colors.HexColor("#4A5568"))

        # Footer (skip page 1 if desired, or include all)
        page_text = f"Page {self._pageNumber} of {page_count}"
        doc_title = "5-Stage Pipelined RV32I RISC-V Core — Final Project Report"
        
        self.drawString(54, 36, doc_title)
        self.drawRightString(612 - 54, 36, page_text)
        
        # Footer line
        self.setStrokeColor(colors.HexColor("#CBD5E0"))
        self.setLineWidth(0.5)
        self.line(54, 48, 612 - 54, 48)
        
        self.restoreState()


def build_pdf(md_path, pdf_path):
    doc = SimpleDocTemplate(
        pdf_path,
        pagesize=letter,
        leftMargin=54,
        rightMargin=54,
        topMargin=54,
        bottomMargin=64
    )

    styles = getSampleStyleSheet()

    # Custom Color Palette
    PRIMARY = colors.HexColor("#1A365D")   # Deep Navy
    SECONDARY = colors.HexColor("#2B6CB0") # Steel Blue
    TEXT_COLOR = colors.HexColor("#2D3748")# Charcoal
    BG_LIGHT = colors.HexColor("#F7FAFC")  # Light Off-white
    BORDER_COLOR = colors.HexColor("#E2E8F0")

    title_style = ParagraphStyle(
        'DocTitle',
        parent=styles['Title'],
        fontName='Helvetica-Bold',
        fontSize=24,
        leading=28,
        textColor=PRIMARY,
        alignment=TA_CENTER,
        spaceAfter=15
    )

    subtitle_style = ParagraphStyle(
        'DocSubtitle',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=12,
        leading=16,
        textColor=SECONDARY,
        alignment=TA_CENTER,
        spaceAfter=25
    )

    h1_style = ParagraphStyle(
        'Heading1_Custom',
        parent=styles['Heading1'],
        fontName='Helvetica-Bold',
        fontSize=15,
        leading=19,
        textColor=PRIMARY,
        spaceBefore=16,
        spaceAfter=8,
        keepWithNext=True
    )

    h2_style = ParagraphStyle(
        'Heading2_Custom',
        parent=styles['Heading2'],
        fontName='Helvetica-Bold',
        fontSize=12,
        leading=16,
        textColor=SECONDARY,
        spaceBefore=12,
        spaceAfter=6,
        keepWithNext=True
    )

    body_style = ParagraphStyle(
        'Body_Custom',
        parent=styles['BodyText'],
        fontName='Helvetica',
        fontSize=10,
        leading=14,
        textColor=TEXT_COLOR,
        alignment=TA_LEFT,
        spaceAfter=6
    )

    bullet_style = ParagraphStyle(
        'Bullet_Custom',
        parent=body_style,
        leftIndent=15,
        firstLineIndent=-10,
        spaceAfter=4
    )

    code_style = ParagraphStyle(
        'Code_Custom',
        parent=styles['Normal'],
        fontName='Courier',
        fontSize=8.5,
        leading=11,
        textColor=colors.HexColor("#1A202C"),
        backColor=BG_LIGHT,
        borderColor=BORDER_COLOR,
        borderWidth=0.5,
        borderPadding=6,
        spaceBefore=6,
        spaceAfter=8
    )

    story = []

    # Title Banner
    story.append(Paragraph("FINAL PROJECT REPORT", title_style))
    story.append(Paragraph("Design and Verification of a 5-Stage Pipelined RV32I RISC-V Core in SystemVerilog", subtitle_style))
    story.append(HRFlowable(width="100%", thickness=1.5, color=PRIMARY, spaceAfter=15))

    with open(md_path, 'r', encoding='utf-8') as f:
        content = f.read()

    lines = content.splitlines()
    in_code = False
    code_block = []
    table_lines = []

    for line in lines:
        raw_line = line.rstrip()

        # Handle Code Blocks
        if raw_line.startswith("```"):
            if in_code:
                in_code = False
                code_text = "<br/>".join(
                    code_line.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace(" ", "&nbsp;")
                    for code_line in code_block
                )
                story.append(Paragraph(code_text, code_style))
                code_block = []
            else:
                in_code = True
                code_block = []
            continue

        if in_code:
            code_block.append(raw_line)
            continue

        # Handle Tables
        if raw_line.startswith("|") and raw_line.endswith("|"):
            table_lines.append(raw_line)
            continue
        elif table_lines:
            # Process accumulated table
            table_data = []
            for tline in table_lines:
                if "---" in tline:
                    continue
                cells = [c.strip() for c in tline.split("|")[1:-1]]
                row_cells = [Paragraph(re.sub(r'\*\*(.*?)\*\*', r'<b>\1</b>', c), body_style) for c in cells]
                table_data.append(row_cells)
            
            if table_data:
                t = Table(table_data, hAlign='LEFT')
                t.setStyle(TableStyle([
                    ('BACKGROUND', (0, 0), (-1, 0), PRIMARY),
                    ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
                    ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
                    ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
                    ('FONTSIZE', (0, 0), (-1, 0), 9),
                    ('BOTTOMPADDING', (0, 0), (-1, -1), 5),
                    ('TOPPADDING', (0, 0), (-1, -1), 5),
                    ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, BG_LIGHT]),
                    ('GRID', (0, 0), (-1, -1), 0.5, BORDER_COLOR),
                ]))
                story.append(t)
                story.append(Spacer(1, 8))
            table_lines = []

        if not raw_line:
            story.append(Spacer(1, 4))
            continue

        # Format Headings & Text
        if raw_line.startswith("# FINAL PROJECT REPORT") or raw_line.startswith("# Design and Verification"):
            continue # Already rendered title banner
        elif raw_line.startswith("## "):
            text = raw_line[3:].strip()
            story.append(Paragraph(text, h1_style))
        elif raw_line.startswith("### "):
            text = raw_line[4:].strip()
            story.append(Paragraph(text, h2_style))
        elif raw_line.startswith("* ") or raw_line.startswith("- "):
            text = raw_line[2:].strip()
            text = re.sub(r'\*\*(.*?)\*\*', r'<b>\1</b>', text)
            text = re.sub(r'`(.*?)`', r'<font face="Courier">\1</font>', text)
            story.append(Paragraph(f"• {text}", bullet_style))
        else:
            text = raw_line
            text = re.sub(r'\*\*(.*?)\*\*', r'<b>\1</b>', text)
            text = re.sub(r'`(.*?)`', r'<font face="Courier">\1</font>', text)
            story.append(Paragraph(text, body_style))

    doc.build(story, canvasmaker=NumberedCanvas)
    print(f"[PDF Generator] Report generated successfully: {pdf_path}")


if __name__ == '__main__':
    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    md_file = os.path.join(project_root, "project_report.md")
    pdf_file = os.path.join(project_root, "RISC-V_Core_Design_Final_Report.pdf")
    build_pdf(md_file, pdf_file)
