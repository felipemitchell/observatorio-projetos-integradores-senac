from django.contrib.auth.models import AbstractUser
from django.db import models

class CustomUser(AbstractUser):
    PERFIL_CHOICES = [
        ('aluno', 'Aluno'),
        ('professor', 'Professor'),
        ('empresa', 'Empresa'),
        ('admin', 'Administrador'),
    ]
    perfil = models.CharField(
        max_length=20,
        choices=PERFIL_CHOICES,
        default='aluno'
    )

    def __str__(self):
        return f"{self.username} ({self.get_perfil_display()})"