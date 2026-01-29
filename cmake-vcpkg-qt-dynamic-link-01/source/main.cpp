// main.cpp

#include <QApplication>
#include <QKeyEvent>
#include <QPushButton>

class EscapableButton : public QPushButton
{
public:
    EscapableButton(const QString& text, QWidget* parent = nullptr)
        : QPushButton(text, parent)
    {
        setFocusPolicy(Qt::StrongFocus);
    }

protected:
    void keyPressEvent(QKeyEvent* event) override
    {
        if(event->key() == Qt::Key_Escape)
        {
            qApp->quit();
        }
        else
        {
            QPushButton::keyPressEvent(event);
        }
    }
};

int main(int argc, char** argv)
{
    QApplication app(argc, argv);

    EscapableButton button("Hello world !");
    button.show();
    button.setFocus();    // Ensure the button has focus to receive key events

    return app.exec();
}