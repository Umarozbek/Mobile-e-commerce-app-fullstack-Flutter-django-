from django.db import transaction
from django.shortcuts import render, redirect, get_object_or_404
from django.urls import reverse_lazy, reverse
from django.utils.http import urlencode
from django.views.generic import ListView, CreateView
from django.views import View
from django.db.models import Q

from apps.product.models import Phone, Ticket, Good, Category, ProductItem, Image
from .forms import (
    PhoneProductItemForm,
    TicketProductItemForm,
    GoodProductItemForm,
    PhoneCategoryCreateForm,
    TicketCategoryCreateForm,
    PhoneEditForm,
    TicketEditForm,
    GoodEditForm,
    GoodMainCategoryCreateForm,
    CategoryEditForm,
    CategoryCreateForm,
    GoodChildProductItemForm,
)


# ==========================================
# 1. PHONE (ELECTRONICS) VIEWS
# ==========================================

class PhoneListView(ListView):
    model = Phone
    template_name = "product/electronics/phone_list.html"
    context_object_name = "phones"
    paginate_by = 10

    def get_queryset(self):
        return Phone.objects.all().select_related('product', 'category').order_by("-pk")


class PhoneCreateView(View):
    template_name = "product/electronics/phone_create.html"

    def get(self, request):
        form = PhoneProductItemForm()
        return render(request, self.template_name, {"form": form})

    def post(self, request):
        form = PhoneProductItemForm(request.POST, request.FILES)
        if form.is_valid():
            form.save()
            return redirect("phone_list")
        return render(request, self.template_name, {"form": form})


class PhoneEditDeleteView(View):
    template_name = "product/electronics/edit_delete_phone.html"

    def get(self, request, pk):
        phone = get_object_or_404(Phone, pk=pk)
        form = PhoneEditForm(instance=phone)
        return render(request, self.template_name, {"form": form, "phone": phone})

    def post(self, request, pk):
        phone = get_object_or_404(Phone, pk=pk)
        form = PhoneEditForm(request.POST, request.FILES, instance=phone)
        if form.is_valid():
            form.save()
            return redirect("phone_list")
        return render(request, self.template_name, {"form": form, "phone": phone})


# ==========================================
# 2. TICKET VIEWS
# ==========================================

class TicketListView(ListView):
    model = Ticket
    template_name = "product/tickets/ticket_list.html"
    context_object_name = "tickets"
    paginate_by = 10

    def get_queryset(self):
        return Ticket.objects.all().select_related('product', 'category').order_by("-pk")


class TicketCreateView(View):
    template_name = "product/tickets/ticket_create.html"

    def get(self, request):
        form = TicketProductItemForm()
        return render(request, self.template_name, {"form": form})

    def post(self, request):
        form = TicketProductItemForm(request.POST, request.FILES)
        if form.is_valid():
            form.save()
            return redirect("ticket-list")
        return render(request, self.template_name, {"form": form})


class TicketEditDeleteView(View):
    template_name = "product/tickets/edit_delete_ticket.html"

    def get(self, request, pk):
        ticket = get_object_or_404(Ticket, pk=pk)
        form = TicketEditForm(instance=ticket)
        return render(request, self.template_name, {"form": form, "ticket": ticket})

    def post(self, request, pk):
        ticket = get_object_or_404(Ticket, pk=pk)
        form = TicketEditForm(request.POST, request.FILES, instance=ticket)
        if form.is_valid():
            form.save()
            return redirect("ticket-list")
        return render(request, self.template_name, {"form": form, "ticket": ticket})


# ==========================================
# 3. GOOD (OZIQ-OVQAT) VIEWS
# ==========================================

from django.db.models import Q
from django.http import Http404


class GoodListView(ListView):
    model = Good
    template_name = "product/goods/good_list.html"
    context_object_name = "goods"
    paginate_by = 25

    def get_paginate_by(self, queryset):
        # URL'da per_page bo'lsa o'shani oladi, bo'lmasa paginate_by dagi 25 ni oladi
        return self.request.GET.get('per_page', self.paginate_by)

    def get_queryset(self):
        query = self.request.GET.get('q', '')
        goods = (
            Good.objects.filter(product__main=True)
            .select_related("product", "category")
            .order_by("-pk")
        )

        if query:
            # 4 tilda qidirish
            goods = goods.filter(
                Q(name_uz__icontains=query) |
                Q(name_ru__icontains=query) |
                Q(name_en__icontains=query) |
                Q(name_ko__icontains=query)
            ).distinct()
        return goods

    # MANA SHU QISIM SAHIFADA QOLISH VA XATOLIKNI OLDINI OLISH UCHUN:
    def paginate_queryset(self, queryset, page_size):
        try:
            return super().paginate_queryset(queryset, page_size)
        except Http404:
            # Agar 2-sahifa topilmasa (qidiruv natijasi kam bo'lsa), 1-sahifaga qaytaradi
            self.request.GET = self.request.GET.copy()
            # Lekin URL parametridagi page raqamini o'zgartirmaymiz
            return super().paginate_queryset(queryset, page_size)


class GoodCreateView(View):
    template_name = "product/goods/good_create.html"

    def get(self, request):
        return render(request, self.template_name, {"form": GoodProductItemForm()})

    def post(self, request):
        form = GoodProductItemForm(request.POST, request.FILES)

        if form.is_valid():
            with transaction.atomic():  # Agar rasmda xato bo'lsa, mahsulot ham yaratilmaydi
                # 1. Mahsulotni saqlash
                good = form.save()
                product_item = good.product

                # 2. Rasmlarni HTMLdagi name="image" bo'yicha olamiz
                images = request.FILES.getlist('image')

                for img in images:
                    Image.objects.create(
                        product=product_item,
                        image=img,
                        name=f"{good.name}_{img.name}"
                    )
                return redirect("good-list")

        return render(request, self.template_name, {"form": form})


class GoodEditDeleteView(View):
    template_name = "product/goods/good_edit.html"

    def get(self, request, pk):
        good = get_object_or_404(Good, pk=pk)
        form = GoodEditForm(instance=good)

        # URL'dan sahifa raqami va qidiruv so'zini olamiz
        page = request.GET.get('page', '1')
        query = request.GET.get('q', '')  # Qidiruvni ham saqlaymiz

        return render(request, self.template_name, {
            "form": form,
            "good": good,
            "page": page,
            "q": query  # Context'ga qo'shdik
        })

    def post(self, request, pk):
        good = get_object_or_404(Good, pk=pk)
        form = GoodEditForm(request.POST, request.FILES, instance=good)

        # Formadan yashirin kelayotgan parametrlar
        page = request.POST.get('page', '1')
        query = request.POST.get('q', '')

        if form.is_valid():
            form.save()
            # Redirect uchun parametrlarni tayyorlaymiz
            base_url = reverse('good-list')
            params = {'page': page}
            if query:
                params['q'] = query

            # Natija: /dashboard/.../?page=3&q=olma
            return redirect(f"{base_url}?{urlencode(params)}")

        # Agar xatolik bo'lsa, parametrlarni qaytarib yuboramiz
        return render(request, self.template_name, {
            "form": form,
            "good": good,
            "page": page,
            "q": query
        })


# --- Mahsulot Variantlari (Children) ---

class ChildrenView(View):
    template_name = "product/goods/product_children.html"
    form_class = GoodChildProductItemForm

    def get_data(self, pk):
        good = get_object_or_404(Good, pk=pk)
        product_type = good.product.product_type
        children = Good.objects.filter(
            product__product_type=product_type, product__main=False
        ).select_related('product')
        return good, children, product_type

    def get(self, request, pk):
        good, children, p_type = self.get_data(pk)
        form = self.form_class(product_type=p_type)
        return render(request, self.template_name, {
            "children": children, "form": form, "good": good
        })

    def post(self, request, pk):
        good, children, p_type = self.get_data(pk)
        form = self.form_class(request.POST, request.FILES, product_type=p_type)
        if form.is_valid():
            form.save()
            return redirect("add_product_child", pk=pk)
        return render(request, self.template_name, {
            "children": children, "form": form, "good": good
        })


# ==========================================
# 4. CATEGORY MANAGEMENT VIEWS
# ==========================================

class CategoryListView(ListView):
    model = Category
    template_name = "product/category_list.html"
    context_object_name = "categories"

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        # MANA SHU QATOR MODAL ICHIDAGI INPUTLARNI CHIQARIB BERADI
        context['form'] = CategoryCreateForm()
        return context


class CategoryCreateView(CreateView):
    model = Category
    form_class = CategoryCreateForm
    template_name = "product/category_create.html"
    success_url = reverse_lazy("category-list")

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context["action"] = "Yangi kategoriya yaratish"
        return context


class CategoryEditView(View):
    template_name = "product/category_edit.html"

    def get(self, request, pk):
        category = get_object_or_404(Category, pk=pk)
        form = CategoryEditForm(instance=category)
        return render(request, self.template_name, {"form": form, "category": category})

    def post(self, request, pk):
        category = get_object_or_404(Category, pk=pk)
        form = CategoryEditForm(request.POST, request.FILES, instance=category)
        if form.is_valid():
            form.save()
            return redirect("category-list")
        return render(request, self.template_name, {"form": form, "category": category})


# ==========================================
# 5. DELETE ACTIONS (Takrorlanishni kamaytirish uchun)
# ==========================================

class BaseDeleteView(View):
    model = None
    success_url = None

    def post(self, request, pk):
        obj = get_object_or_404(self.model, pk=pk)
        # Agar mahsulot bo'lsa, bog'liq ProductItemni ham o'chiradi
        if hasattr(obj, 'product'):
            p_item = obj.product
            obj.delete()
            p_item.delete()
        else:
            obj.delete()
        return redirect(self.success_url)


class PhoneDeleteView(BaseDeleteView):
    model = Phone
    success_url = "phone_list"


class TicketDeleteView(BaseDeleteView):
    model = Ticket
    success_url = "ticket-list"


class GoodDeleteView(BaseDeleteView):
    model = Good
    success_url = "good-list"


class CategoryDeleteView(BaseDeleteView):
    model = Category
    success_url = "category-list"


class ChildActionView(View):
    def post(self, request, *args, **kwargs):
        action = request.POST.get("action")
        parent_pk = kwargs.get("parent_pk")
        child_pk = kwargs.get("pk")
        child = get_object_or_404(Good, pk=child_pk)

        if action == "toggle":
            child.product.active = not child.product.active
            child.product.save()
        elif action == "delete":
            p_item = child.product
            child.delete()
            p_item.delete()

        return redirect("add_product_child", pk=parent_pk)


# --- Eskirgan (SubCategory) Viewlar butunlay olib tashlandi ---


class PhoneCategoryCreateView(CreateView):
    model = Category
    form_class = PhoneCategoryCreateForm
    template_name = "product/category_create.html"
    success_url = reverse_lazy("create_phone")

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context["action"] = "Create New Phone Category"
        return context

    def form_valid(self, form):
        form.instance.main_type = "p"
        return super().form_valid(form)

    def form_invalid(self, form):
        return super().form_invalid(form)


class TicketCategoryCreateView(CreateView):
    model = Category
    form_class = TicketCategoryCreateForm
    template_name = "product/category_create.html"
    success_url = reverse_lazy("ticket_create")

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context["action"] = "Create New Ticket Category"
        return context

    def form_valid(self, form):
        form.instance.main_type = "t"
        return super().form_valid(form)


class GoodMainCategoryCreateView(CreateView):
    model = Category
    form_class = GoodMainCategoryCreateForm
    template_name = "product/goods/category_create.html"
    success_url = reverse_lazy("good_subcategory")

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context["action"] = "Create New Good Category"
        return context

    def form_valid(self, form):
        form.instance.main_type = "f"
        return super().form_valid(form)


def delete_good(request, pk):
    if request.method == 'POST':
        good = get_object_or_404(Good, pk=pk)
        good.delete()

        # Formadan kelgan yashirin parametrlarni olamiz
        page = request.POST.get('page', '1')
        query = request.POST.get('q', '')
        per_page = request.POST.get('per_page', '')

        # Qayta yo'naltirish URL manzilini yasaymiz
        base_url = reverse('good-list')
        params = {'page': page}

        if query:
            params['q'] = query
        if per_page:
            params['per_page'] = per_page

        # URL natijasi: /dashboard/.../?page=3&q=olma&per_page=50
        return redirect(f"{base_url}?{urlencode(params)}")

    return redirect('good-list')


def bulk_delete_goods(request):
    if request.method == 'POST':
        selected_ids = request.POST.getlist('selected_ids')  # Tanlangan ID-lar ro'yxati
        if selected_ids:
            Good.objects.filter(id__in=selected_ids).delete()

        # Holatni saqlab qolish
        page = request.POST.get('page', '1')
        query = request.POST.get('q', '')
        per_page = request.POST.get('per_page', '')

        base_url = reverse('good-list')
        params = {'page': page}
        if query: params['q'] = query
        if per_page: params['per_page'] = per_page

        return redirect(f"{base_url}?{urlencode(params)}")

    return redirect('good-list')
