import './bootstrap';
import Alpine from 'alpinejs';
import 'flowbite';

// Initialize Alpine.js
window.Alpine = Alpine;
Alpine.start();

// Initialize TinyMCE if it's loaded
if (typeof tinymce !== 'undefined') {
    tinymce.init({
        selector: '.tinymce',
        plugins: 'advlist autolink lists link image charmap preview anchor searchreplace visualblocks code fullscreen insertdatetime media table code help wordcount',
        toolbar: 'undo redo | formatselect | bold italic backcolor | alignleft aligncenter alignright alignjustify | bullist numlist outdent indent | removeformat | help',
        height: 400,
        menubar: false
    });
}

// Flash message handling
const flashMessage = (message, type = 'success') => {
    const alert = document.createElement('div');
    alert.className = `alert alert-${type} fixed top-4 right-4 z-50 max-w-sm`;
    alert.innerHTML = message;
    document.body.appendChild(alert);
    
    setTimeout(() => {
        alert.remove();
    }, 3000);
};

window.flashMessage = flashMessage;

// Image preview
const setupImagePreview = () => {
    const imageInput = document.querySelector('input[type="file"][accept="image/*"]');
    const imagePreview = document.querySelector('.image-preview');
    
    if (imageInput && imagePreview) {
        imageInput.addEventListener('change', (e) => {
            const file = e.target.files[0];
            if (file) {
                const reader = new FileReader();
                reader.onload = (e) => {
                    imagePreview.src = e.target.result;
                    imagePreview.classList.remove('hidden');
                };
                reader.readAsDataURL(file);
            }
        });
    }
};

// Confirmation dialogs
const confirmAction = (message = 'Are you sure?') => {
    return new Promise((resolve) => {
        if (window.confirm(message)) {
            resolve(true);
        } else {
            resolve(false);
        }
    });
};

window.confirmAction = confirmAction;

// Form validation
const validateForm = (form) => {
    const requiredFields = form.querySelectorAll('[required]');
    let isValid = true;
    
    requiredFields.forEach(field => {
        if (!field.value.trim()) {
            field.classList.add('border-red-500');
            isValid = false;
            
            const errorMessage = document.createElement('p');
            errorMessage.className = 'text-red-500 text-sm mt-1';
            errorMessage.textContent = `${field.name} is required`;
            
            if (!field.nextElementSibling?.classList.contains('text-red-500')) {
                field.parentNode.insertBefore(errorMessage, field.nextSibling);
            }
        } else {
            field.classList.remove('border-red-500');
            if (field.nextElementSibling?.classList.contains('text-red-500')) {
                field.nextElementSibling.remove();
            }
        }
    });
    
    return isValid;
};

// Initialize components
document.addEventListener('DOMContentLoaded', () => {
    setupImagePreview();
    
    // Form validation
    const forms = document.querySelectorAll('form');
    forms.forEach(form => {
        form.addEventListener('submit', (e) => {
            if (!validateForm(form)) {
                e.preventDefault();
            }
        });
    });
    
    // Dropdown menus
    const dropdowns = document.querySelectorAll('.dropdown-toggle');
    dropdowns.forEach(dropdown => {
        dropdown.addEventListener('click', () => {
            const menu = dropdown.nextElementSibling;
            menu.classList.toggle('hidden');
        });
    });
    
    // Close dropdowns when clicking outside
    document.addEventListener('click', (e) => {
        if (!e.target.matches('.dropdown-toggle')) {
            document.querySelectorAll('.dropdown-menu').forEach(menu => {
                if (!menu.classList.contains('hidden')) {
                    menu.classList.add('hidden');
                }
            });
        }
    });
});
