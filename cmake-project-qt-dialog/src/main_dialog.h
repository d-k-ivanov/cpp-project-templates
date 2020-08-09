#pragma once

#include <QDialog>
#include <QQueue>

QT_BEGIN_NAMESPACE
class QDialogButtonBox;
class QGridLayout;
class QLabel;
class QPushButton;
QT_END_NAMESPACE

class Dialog : public QDialog
{
    Q_OBJECT

public:
    Dialog(QWidget *parent = 0);

private slots:
    void help();

private:
    void createButtonBox();

    QDialogButtonBox *buttonBox;
    QPushButton *closeButton;
    QPushButton *helpButton;

    QGridLayout *mainLayout;
};
