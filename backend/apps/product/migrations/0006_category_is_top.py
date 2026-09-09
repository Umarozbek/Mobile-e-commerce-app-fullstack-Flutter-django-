from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('product', '0005_productitem_name'),
    ]

    operations = [
        migrations.AddField(
            model_name='category',
            name='is_top',
            field=models.BooleanField(default=False),
        ),
    ]
