#include <QtWidgets>

#include "main_dialog.h"

Dialog::Dialog(QWidget *parent)
    : QDialog(parent)
{
    createButtonBox();

    mainLayout = new QGridLayout;
    mainLayout->addWidget(buttonBox, 2, 0);
    setLayout(mainLayout);

    mainLayout->setSizeConstraint(QLayout::SetMinimumSize);

    setWindowTitle(tr("QT DIALOG"));
}

void Dialog::help()
{
    QMessageBox::information(this, tr("QT DIALOG Help"), tr("Init QT DIALOG Help Text."));
}


void Dialog::createButtonBox()
{
    buttonBox = new QDialogButtonBox;

    closeButton = buttonBox->addButton(QDialogButtonBox::Close);
    helpButton = buttonBox->addButton(QDialogButtonBox::Help);

    connect(closeButton, &QPushButton::clicked, this, &Dialog::close);
    connect(helpButton, &QPushButton::clicked, this, &Dialog::help);
}


