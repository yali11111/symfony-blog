

php bin/console make:entity Rating

# src/Entity/Rating.php
// src/Entity/Rating.php
namespace App\Entity;

use App\Repository\RatingRepository;
use Doctrine\ORM\Mapping as ORM;

#[ORM\Entity(repositoryClass: RatingRepository::class)]
class Rating
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column]
    private ?int $id = null;

    #[ORM\Column]
    private ?int $value = null;

    #[ORM\ManyToOne(inversedBy: 'ratings')]
    #[ORM\JoinColumn(nullable: false)]
    private ?Article $article = null;

    #[ORM\ManyToOne]
    private ?User $user = null;

    #[ORM\Column]
    private ?\DateTimeImmutable $createdAt = null;

    public function __construct()
    {
        $this->createdAt = new \DateTimeImmutable();
    }

    // Getters et Setters...
}



// src/Entity/Article.php
#[ORM\OneToMany(mappedBy: 'article', targetEntity: Rating::class, orphanRemoval: true)]
private Collection $ratings;

public function __construct()
{
    $this->ratings = new ArrayCollection();
}

// Ajoute ces méthodes :
public function getAverageRating(): float
{
    if ($this->ratings->isEmpty()) {
        return 0;
    }
    $sum = array_reduce($this->ratings->toArray(), fn($carry, $rating) => $carry + $rating->getValue(), 0);
    return $sum / $this->ratings->count();
}

public function addRating(Rating $rating): self
{
    if (!$this->ratings->contains($rating)) {
        $this->ratings[] = $rating;
        $rating->setArticle($this);
    }
    return $this;
}



php bin/console make:form RatingType


// src/Form/RatingType.php
namespace App\Form;

use Symfony\Component\Form\AbstractType;
use Symfony\Component\Form\FormBuilderInterface;
use Symfony\Component\OptionsResolver\OptionsResolver;
use Symfony\Component\Form\Extension\Core\Type\ChoiceType;

class RatingType extends AbstractType
{
    public function buildForm(FormBuilderInterface $builder, array $options): void
    {
        $builder
            ->add('value', ChoiceType::class, [
                'choices' => [
                    '1 - Très mauvais' => 1,
                    '2 - Mauvais' => 2,
                    '3 - Moyen' => 3,
                    '4 - Bon' => 4,
                    '5 - Excellent' => 5,
                ],
                'label' => 'Note',
            ]);
    }

    public function configureOptions(OptionsResolver $resolver): void
    {
        $resolver->setDefaults([
            'data_class' => Rating::class,
        ]);
    }
}

Créer un template pour le formulaire : templates/article/_rate.html.twig
// src/Controller/ArticleController.php
use App\Entity\Rating;
use App\Form\RatingType;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Annotation\Route;

#[Route('/article/{id}/rate', name: 'article_rate')]
public function rate(Article $article, Request $request, EntityManagerInterface $entityManager): Response
{
    $rating = new Rating();
    $rating->setArticle($article);
    $rating->setUser($this->getUser()); // Si connecté

    $form = $this->createForm(RatingType::class, $rating);
    $form->handleRequest($request);

    if ($form->isSubmitted() && $form->isValid()) {
        $entityManager->persist($rating);
        $entityManager->flush();

        $this->addFlash('success', 'Merci pour votre note !');
        return $this->redirectToRoute('article_show', ['id' => $article->getId()]);
    }

    return $this->render('article/_rate.html.twig', [
        'article' => $article,
        'form' => $form->createView(),
    ]);
}


{# Affichage de la note moyenne #}
<div class="rating">
    Note moyenne : {{ article.averageRating|number_format(1) }}/5
</div>

{# Lien vers le formulaire de notation #}
{% if app.user %}
    <a href="{{ path('article_rate', {'id': article.id}) }}" class="btn btn-primary">Noter cet article</a>
{% endif %}


{% extends 'base.html.twig' %}

{% block body %}
    <h1>Noter : {{ article.title }}</h1>
    {{ form_start(form) }}
        {{ form_widget(form) }}
        <button type="submit" class="btn btn-primary">Envoyer</button>
    {{ form_end(form) }}
{% endblock %}


// Dans l'action rate()
$user = $this->getUser();
$existingRating = $entityManager->getRepository(Rating::class)->findOneBy([
    'article' => $article,
    'user' => $user,
]);

if ($existingRating) {
    $this->addFlash('warning', 'Vous avez déjà noté cet article.');
    return $this->redirectToRoute('article_show', ['id' => $article->getId()]);
}



<div class="star-rating">
    {% for i in 1..5 %}
        {% if i <= article.averageRating|round %}
            <i class="fas fa-star"></i>
        {% else %}
            <i class="far fa-star"></i>
        {% endif %}
    {% endfor %}
</div>


<div class="star-rating">
    {% for i in 1..5 %}
        {% if i <= article.averageRating|round %}
            <i class="fas fa-star"></i>
        {% else %}
            <i class="far fa-star"></i>
        {% endif %}
    {% endfor %}
</div>


Mettre à jour la base de données
Exécute les migrations :
bash
Copier

php bin/console make:migration
php bin/console doctrine:migrations:migrate

php bin/console make:migration
php bin/console doctrine:migrations:migrate

